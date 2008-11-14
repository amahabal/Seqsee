use 5.10.0;
use strict;
use Statistics::Basic qw{:all};

use lib 'genlib';
use Test::Seqsee;
use Global;
use List::Util qw{min max sum};
use Time::HiRes qw{time};
use Getopt::Long;
use Storable;
use File::Slurp;
use Smart::Comments;

my %options;
GetOptions( \%options, "filename=s" );
$options{filename} || confess "Need filename!";

#============
my @SequencesOfInterest;
my %SequencesOfInterest;
my @AllData;
my @FilteredData;
my %FilteredData;
my %FeatureDistribution;
my @Filters;

ReadSequencesInFile( $options{filename} );
ReadAllData();
### %FeatureDistribution: %FeatureDistribution
## %FilteredData: %FilteredData
PrintFilteredData();

sub TrimSequence {
    my ($sequence_string) = @_;
    $sequence_string =~ s#^\s*##;
    $sequence_string =~ s#\s*##;
    return join( ' ', split( /\D+/, $sequence_string ) );
}

sub NormalizeTestSequence {
    my ($sequence_string) = @_;
    my ( $prior, $posterior ) = split( /\|/, $sequence_string );
    join( '', TrimSequence($prior), '|', TrimSequence($posterior) );
}

sub ReadSequencesInFile {
    my ($filename) = @_;
    open my $IN, '<', $filename;
    while ( my $line = <$IN> ) {
        $line =~ /\S/ or next;
        my $normalized = NormalizeTestSequence($line);
        $SequencesOfInterest{$normalized} = 1;
        push @SequencesOfInterest, $normalized;
    }
}

sub ReadAllData {
    for my $filename (<performance/data/*>) {
        my $text       = read_file($filename);
        my $result_set = Storable::thaw($text);
        my $sequence   = NormalizeTestSequence( $result_set->get_terms );
        next unless $SequencesOfInterest{$sequence};
        push @AllData,      $result_set;
        push @FilteredData, $result_set;
    }
    SetFeatureDistribution();
}

sub SetFeatureDistribution {
    %FeatureDistribution = ();
    %FilteredData = ();
    for (@FilteredData) {
        my $terms = NormalizeTestSequence($_->get_terms);
        my $version = $_->get_version();
        my $features = NormalizeFeatures($_->get_features());
        my @results = map { Storable::thaw($_) } @{$_->get_results};
        my @steps = map { $_->get_steps() } @results;

        $FeatureDistribution{version}{$version}++;
        $FeatureDistribution{features}{$features}++;
        push(@{$FilteredData{$terms}{steps}}, @steps);
    }
}

sub NewFilter {
    my ($filter) = @_;
    push @Filters, $filter;
    ApplyFilter($filter);
}

sub ApplyFilter {
    my ($filter) = @_;
    my ($name, @options) = @$filter;
    if ($name eq 'version') {
        my ($min, $max) = @options;
        FilterVersion($min, $max);
    } elsif ($name eq 'features') {
        my ($features) = @options;
        FilterFeatures($features);
    } else {
        die "Unknown filter $name";
    }
}

sub FilterFeatures {
    my ($features) = @_;
    @FilteredData = grep {
        NormalizeFeatures($_->get_features()) eq $features
    } @FilteredData;
}

sub FilterVersion {
    my ($min, $max) = @_;
    my ($minv, $minr) = split(':', $min);
    my ($maxv, $maxr) = split(':', $max);

    @FilteredData = grep {
        my ($v, $r) = split(':', $_->get_version());
        ($minv < $v or ($minv == $v and $minr <= $r)) and
        ($maxv > $v or ($maxv == $v and $maxr >= $r));
    } @FilteredData;
}

sub UndoLastFilter {
    pop @Filters;
    @FilteredData = @AllData;
    for (@Filters) {
        ApplyFilter($_);
    }
}
    

sub NormalizeFeatures {
    my ($features_string) = @_;
    # TODO: dummy fn...
    return $features_string;
}

sub PrintFilteredData {
    foreach my $seq (@SequencesOfInterest) {
        my $steps_ref = $FilteredData{$seq}{steps};
        print "$seq\n";
        PrintStats($steps_ref);
    }
}
  
sub PrintStats {
    my ($array_ref) = @_;
    print "\tCount:\t", scalar(@$array_ref), "\n";
    my $vector = vector($array_ref);
    print "\tMean:\t", mean($array_ref), "\n";
    print "\tStddev:\t", stddev($array_ref), "\n";
}


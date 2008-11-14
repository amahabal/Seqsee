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
use IO::Prompt;

my %options;
GetOptions( \%options, "filename=s", "minv=s", "maxv=s", "features=s",
    "allversions!", "allfeatures!" );
$options{filename} || confess "Need filename!";

my $VersionFilterProvided = 1
  if ( defined( $options{minv} )
    or defined( $options{maxv} )
    or $options{allversions} );
my $FeatureFilterProvided = 1
  if ( defined( $options{features} ) or $options{allfeatures} );

#============
my @SequencesOfInterest;
my %SequencesOfInterest;
my @AllData;
my @FilteredData;
my %FilteredData;
my %FeatureDistribution;
my @Filters;

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
    %FilteredData        = ();
    for (@FilteredData) {
        my $terms    = NormalizeTestSequence( $_->get_terms );
        my $version  = $_->get_version();
        my $features = NormalizeFeatures( $_->get_features() );
        my @results  = map { Storable::thaw($_) } @{ $_->get_results };
        my @steps    = map { $_->get_steps() } @results;

        $FeatureDistribution{version}{$version}++;
        $FeatureDistribution{features}{$features}++;
        push( @{ $FilteredData{$terms}{steps} }, @steps );
    }
}

sub NewFilter {
    my ($filter) = @_;
    push @Filters, $filter;
    ApplyFilter($filter);
}

sub ApplyFilter {
    my ($filter) = @_;
    my ( $name, @options ) = @$filter;
    if ( $name eq 'version' ) {
        my ( $min, $max ) = @options;
        FilterVersion( $min, $max );
    }
    elsif ( $name eq 'features' ) {
        my ($features) = @options;
        FilterFeatures($features);
    }
    else {
        die "Unknown filter $name";
    }
    SetFeatureDistribution();
}

sub FilterFeatures {
    my ($features) = @_;
    @FilteredData =
      grep { NormalizeFeatures( $_->get_features() ) eq $features }
      @FilteredData;
}

sub FilterVersion {
    my ( $min,  $max )  = @_;
    my ( $minv, $minr ) = split( ':', $min );
    my ( $maxv, $maxr ) = split( ':', $max );

    @FilteredData = grep {
        my ( $v, $r ) = split( ':', $_->get_version() );
        ( $minv < $v or ( $minv == $v and $minr <= $r ) )
          and ( $maxv > $v or ( $maxv == $v and $maxr >= $r ) );
    } @FilteredData;
}

sub UndoLastFilter {
    pop @Filters;
    @FilteredData = @AllData;
    for (@Filters) {
        ApplyFilter($_);
    }
}

{
    my @Inconsequential_features = qw{debug CodeletTree
      LogActivations debugMAX};
    my %Inconsequential_features =
      map { ( "-f=$_" => 1 ) } @Inconsequential_features;

    ### Inconsequential_features: %Inconsequential_features

    sub NormalizeFeatures {
        my ($features_string) = @_;
        return '' unless $features_string;

        my @parts =
          grep { !$Inconsequential_features{$_} }
          split( ';', $features_string );
        return '' unless @parts;
        return join( ';', @parts );
    }
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
    print "\tMean:\t",   mean($array_ref),   "\n";
    print "\tStddev:\t", stddev($array_ref), "\n";
}

sub DecideFiltersAndApply {
    DecideVersionFilterAndApply();
    DecideFeatureFilterAndApply();
}

sub DecideVersionFilterAndApply {
    if ($VersionFilterProvided) {
        return if $options{allversions};
        my $minv = $options{minv} // "0:0";
        my $maxv = $options{maxv} // "100000: 100000";
        $maxv = "$maxv:10000" unless $maxv =~ /:/;
        NewFilter( [ 'version', $minv, $maxv ] );
        return;
    }
    else {
        InteractiveVersionFilterAndApply();
    }
}

sub DecideFeatureFilterAndApply {
    if ($FeatureFilterProvided) {
        return if $options{allfeatures};
        NewFilter( [ 'features', $options{features} ] );
        return;
    }
    else {
        InteractiveFeaturesFilterAndApply();
    }
}

sub InteractiveVersionFilterAndApply {
    my @versions = keys( %{ $FeatureDistribution{version} } );
    return if @versions == 1;
    die "No versions left!" unless @versions;

    @versions = sort { CompareVersions( $a, $b ) } @versions;
    say "Data from multiple versions of Seqsee available:\n",
      join( ', ', @versions );

    say "You can narrow this down. ";
    my $minv = prompt( 'minimum version: ', -m => \@versions );
    my $maxv = prompt( 'maximum version: ', -m => \@versions );
    NewFilter( [ 'version', $minv, $maxv ] );
    return;
}

sub InteractiveFeaturesFilterAndApply {
    my @features = keys( %{ $FeatureDistribution{features} } );
    return if @features <= 1;
    say
      "Data from runs of Seqsee with different features turned onavailable:\n",
      join( ', ', @features );
    say "You can narrow this down. ";
    my $feature_set =
      prompt( "Choose feature sets: ", -m => [ @features, 'ALL' ] );
    NewFilter( [ 'features', $feature_set ] ) unless $feature_set eq 'ALL';
    return;
}

sub CompareVersions {
    my ( $v1, $v2 ) = @_;
    my @v1 = split( ':', $v1 );
    my @v2 = split( ':', $v2 );
    return ( $v1[0] <=> $v2[0] ) || ( $v1[1] <=> $v2[1] );
}

ReadSequencesInFile( $options{filename} );
ReadAllData();

DecideFiltersAndApply();
### %FeatureDistribution: %FeatureDistribution
## %FilteredData: %FilteredData
PrintFilteredData();


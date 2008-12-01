use 5.10.0;

package FilterableResultSets;
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

use Class::Std;
use FilterableResults;
use ResultSetOfIndividualRuns;

my %sequences_filename_of :
  ATTR(:get<sequences_filename> :set<sequences_filename>);
my %sequences_to_track_href_of :
  ATTR(:get<sequences_to_track_href> :set<sequences_to_track_href>
);
my %sequences_to_track_aref_of :
  ATTR(:get<sequences_to_track_aref> :set<sequences_to_track_aref>);
my %acceptable_revealed_seqeunces_of :ATTR(:get<acceptable_revealed_seqeunces> :set<acceptable_revealed_seqeunces>);


my %data_of : ATTR(:get<data> :set<data>);
my %ltm_data_of :ATTR(:get<ltm_data> :set<ltm_data>);


my %versions_in_data_of : ATTR(:get<versions_in_data> :set<versions_in_data>);
my %feature_sets_in_data_of :
  ATTR(:get<feature_sets_in_data> :set<feature_sets_in_data>);
my %unfiltered_result_sets_of :
  ATTR(:get<unfiltered_result_sets> :set<unfiltered_result_sets>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;

    $sequences_to_track_aref_of{$id} ||= [];
    $sequences_to_track_href_of{$id} ||= {};

    $sequences_filename_of{$id} = $opts_ref->{sequences_filename}
      || die "sequences_filename needed for FilterableResultSets!";

    $self->ReadSequencesToTrack();
    $self->ReadAllData();
    $self->ReadAllLTMData();

    ( $versions_in_data_of{$id}, $feature_sets_in_data_of{$id} ) =
      GetFeatureAndVersionDistribution( $data_of{$id} );

    $unfiltered_result_sets_of{$id} = FilterableResults->new(
        {
            filters    => [],
            result_set => $self,
            is_human_data => 0, # It could be mixed. We aren't using this. Fix.
        }
    );
}

sub ReadSequencesToTrack {
    my ($self) = @_;
    my $filename = $self->get_sequences_filename;

    my @seq = ReadSequencesInFile($filename);
    @{ $self->get_sequences_to_track_aref() } = @seq;
    %{ $self->get_sequences_to_track_href() } = map { $_ => 1 } @seq;

    my %acceptable_revealed_seqeunces;
    for my $seq (@seq) {
        $seq =~ m{ (.*) \|}x;
        $acceptable_revealed_seqeunces{$1} = $seq;
    }
    $self->set_acceptable_revealed_seqeunces(\%acceptable_revealed_seqeunces);
}

sub ReadAllData {
    my $self                    = shift;
    my $acceptable_revealed_seqeunces_href = $self->get_acceptable_revealed_seqeunces();
    my @all_data;

    for my $filename (<performance/data/* performance/human_data/*>) {
        my $text       = read_file($filename);
        my $result_set = Storable::thaw($text);
        my $sequence   = NormalizeTestSequence( $result_set->get_terms );
        $sequence =~ m{ (.*) \|}x;
        my $revealed = $1;
        $sequence = $acceptable_revealed_seqeunces_href->{$revealed} or next;

        $result_set->set_terms($sequence);
        push @all_data, $result_set;
    }

    $self->set_data( \@all_data );
}

sub ReadAllLTMData {
    my $self                    = shift;
    my @all_data;

    for my $filename (<performance/ltm_data/*>) {
        my $text       = read_file($filename);
        my $result_set = Storable::thaw($text);
        my $sequence   = NormalizeTestSequence( $result_set->get_terms );
        $sequence =~ m{ (.*) \|}x;
        my $revealed = $1;
        $result_set->set_terms($sequence);
        
        push @all_data, $result_set;
    }

    $self->set_ltm_data( \@all_data );
}

## UTILITY FUNCTIONS:
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

    my @ret;
    while ( my $line = <$IN> ) {
        $line =~ /\S/ or next;
        my $normalized = NormalizeTestSequence($line);
        push @ret, $normalized;
    }

    @ret;
}

sub GetFeatureAndVersionDistribution {
    my @data = @_;
    if ( ref( $data[0] ) eq 'ARRAY' ) {
        @data = @{ $data[0] };
    }

    my %versions;
    my %feature_sets;

    for (@data) {
        my $terms    = NormalizeTestSequence( $_->get_terms );
        my $version  = $_->get_version();
        my $features = NormalizeFeatures( $_->get_features() );
        $versions{$version}++;
        $feature_sets{$features}++;
    }
    return ( [ keys %versions ], [ keys %feature_sets ] );
}

sub CompareVersions {
    my ( $v1, $v2 ) = @_;
    my @v1 = split( ':', $v1 );
    my @v2 = split( ':', $v2 );
    return ( $v1[0] <=> $v2[0] ) || ( $v1[1] <=> $v2[1] );
}

{
    my @Inconsequential_features = qw{debug CodeletTree
      LogActivations debugMAX};
    my %Inconsequential_features =
      map { ( "-f=$_" => 1 ) } @Inconsequential_features;

    ## Inconsequential_features: %Inconsequential_features

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

sub PrintSummary {
    my ($self) = @_;
    my $id = ident $self;

    print "ALL DATA RELEVANT TO SEQUENCES IN $sequences_filename_of{$id}\n";
    print "Datafile count: ", scalar( @{ $data_of{$id} } ), "\n";
    print "Versions: ", join( ', ', @{ $versions_in_data_of{$id} } ), "\n";
    print "Feature sets:\n\t",
      join( "\n\t", map { "'$_'" } @{ $feature_sets_in_data_of{$id} } ), "\n";
}

sub PrintResults {
    my ($self) = @_;
    my $id = ident $self;
    $unfiltered_result_sets_of{$id}->PrintResults();
}

sub HasMultipleVersions {
    my ($self) = @_;
    my $id = ident $self;

    scalar( @{ $versions_in_data_of{$id} } ) > 1 ? 1 : 0;
}

sub HasMultipleFeatureSets {
    my ( $self, ) = @_;
    my $id = ident $self;

    scalar( @{ $feature_sets_in_data_of{$id} } ) > 1 ? 1 : 0;
}

1;

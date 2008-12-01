use 5.10.0;

package FilterableResults;
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
use Carp;

# Objects that have passed our filters.
my %filtered_data_of : ATTR(:get<filtered_data>);

# Filters in place.
my %filters_of : ATTR(:name<filters>);

my %is_human_data_of : ATTR(:name<is_human_data>);
my %is_ltm_data_of : ATTR(:get<is_ltm_data> :set<is_ltm_data>);
my %is_ltm_self_context_of :
  ATTR(:get<is_ltm_self_context> :set<is_ltm_self_context>);

my %result_set_of : ATTR(:name<result_set>);
my %results_by_sequence_of :
  ATTR(:get<results_by_sequence> :set<results_by_sequence>);

my $HUMAN_FILTER = [ 'features', 'human' ];
my $INHUMAN_FILTER = ['inhuman'];

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;

    $result_set_of{$id} = $opts_ref->{result_set};
    my $is_human_data = $is_human_data_of{$id} = $opts_ref->{is_human_data};
    my $is_ltm_data   = $is_ltm_data_of{$id}   = $opts_ref->{is_ltm_data};
    my $is_ltm_self_context = $is_ltm_self_context_of{$id} =
      $opts_ref->{is_ltm_self_context};

    if ($is_ltm_data) {
        $filtered_data_of{$id} = [ @{ $result_set_of{$id}->get_ltm_data() } ];
    }
    else {
        $filtered_data_of{$id} = [ @{ $result_set_of{$id}->get_data() } ];
    }

    if ($is_human_data) {
        $filters_of{$id} = [$HUMAN_FILTER];
    }
    else {
        $filters_of{$id} = [ $INHUMAN_FILTER, @{ $opts_ref->{filters} } ]
          || [$INHUMAN_FILTER];
    }

    for my $filter ( @{ $filters_of{$id} } ) {
        $self->ApplyFilter($filter);
    }

    my %by_sequence;
    my @sequences_to_track;
    if ($is_ltm_self_context) {
        # Add stuff indexed by position, not sequence!
        my $result_set = $result_set_of{$id};
        ### result_set: $result_set

        my @LTM_Results = @{$result_set->get_ltm_data()};
        ### LTM_Results: @LTM_Results

        my $sequence_under_consideration = $opts_ref->{sequence};
        $sequence_under_consideration =~ m#(.*)\|#;
        my $revealed_terms = FilterableResultSets::TrimSequence($1);
        my @acceptable_LTM_results = grep {
            my $terms = $_->get_terms;
            $terms =~ m#(.*)\|#;
            FilterableResultSets::TrimSequence($1) eq $revealed_terms;
        } @LTM_Results;

        ### acceptable_LTM_results: @acceptable_LTM_results

        for my $results_of_test (@acceptable_LTM_results) {
            my @results = map { Storable::thaw($_)} @{$results_of_test->get_results};
            for my $idx (1..10) {
                push @{ $by_sequence{"iteration_$idx"}}, $results[$idx - 1];
                ### num, res: $idx, $results[$idx -1]
            }
        }
        @sequences_to_track = map { "iteration_$_" } (1..10);
        ### sequences_to_track: @sequences_to_track
    }
    else {

        for my $result_set ( @{ $filtered_data_of{$id} } ) {
            my $seq = $result_set->get_terms;
            my @results =
              map { Storable::thaw($_) } @{ $result_set->get_results };

            if ($is_human_data) {
                for (@results) {
                    $_->set_steps( $_->get_steps() * 100 );
                }
            }

            push @{ $by_sequence{$seq} }, @results;
        }
        @sequences_to_track = @{ $result_set_of{$id}->get_sequences_to_track_aref() };
    }

    for my $seq (@sequences_to_track) {
        my $results_ref = $by_sequence{$seq} || [];
        my $rsir =
          ResultSetOfIndividualRuns->new( { results => $results_ref } );
        $by_sequence{$seq} = $rsir;
    }
    $results_by_sequence_of{$id} = \%by_sequence;
}

sub PrintResults {
    my ($self) = @_;
    my $id = ident $self;

    while ( my ( $seq, $rsir ) = each %{ $results_by_sequence_of{$id} } ) {
        print '=' x 20, "\n", $seq, "\n\n";
        $rsir->DisplayStatus();
    }
}

sub ApplyFilter {
    my ( $self, $filter ) = @_;
    my $id = ident $self;

    my ( $name, @options ) = @$filter;
    if ( $name eq 'version' ) {
        my ( $min, $max ) = @options;
        $self->FilterVersion( $min, $max );
    }
    elsif ( $name eq 'features' ) {
        my ($features) = @options;
        $self->FilterFeatures($features);
    }
    elsif ( $name eq 'inhuman' ) {
        $self->FilterInhuman();
    }
    else {
        die "Unknown filter $name";
    }
}

sub FilterFeatures {
    my ( $self, $features ) = @_;
    my $id = ident $self;

    @{ $filtered_data_of{$id} } =
      grep {
        FilterableResultSets::NormalizeFeatures( $_->get_features() ) eq
          $features
      } @{ $filtered_data_of{$id} };
}

sub FilterInhuman {
    my ($self) = @_;
    my $id = ident $self;

    @{ $filtered_data_of{$id} } = grep {
        FilterableResultSets::NormalizeFeatures( $_->get_features() ) ne 'human'
    } @{ $filtered_data_of{$id} };
}

sub FilterVersion {
    my ( $self, $min, $max ) = @_;
    my $id = ident $self;

    my ( $minv, $minr ) = split( ':', $min );
    my ( $maxv, $maxr ) = split( ':', $max );

    @{ $filtered_data_of{$id} } = grep {
        my ( $v, $r ) = split( ':', $_->get_version() );
        ( $minv < $v or ( $minv == $v and $minr <= $r ) )
          and ( $maxv > $v or ( $maxv == $v and $maxr >= $r ) );
    } @{ $filtered_data_of{$id} };
}

1;

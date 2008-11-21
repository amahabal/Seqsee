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

my %result_set_of : ATTR(:name<result_set>);
my %results_by_sequence_of :
  ATTR(:get<results_by_sequence> :set<results_by_sequence>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;

    $result_set_of{$id} = $opts_ref->{result_set};
    $filtered_data_of{$id} = [ @{ $result_set_of{$id}->get_data() } ];
    for my $filter ( @{ $filters_of{$id} } ) {
        $self->ApplyFilter();
    }

    my %by_sequence;
    for my $result_set ( @{ $filtered_data_of{$id} } ) {
        my $seq = $result_set->get_terms;
        my @results = map { Storable::thaw($_) } @{ $result_set->get_results };
        push @{ $by_sequence{$seq} }, @results;
    }

    my @sequences_to_track =
      @{ $result_set_of{$id}->get_sequences_to_track_aref() };
    for my $seq (@sequences_to_track) {
        my $results_ref = $by_sequence{$seq} || [];
        my $rsir =
          ResultSetOfIndividualRuns->new( { results => $results_ref } );
        $by_sequence{$seq} = $rsir;
    }
    $results_by_sequence_of{$id} = \%by_sequence;
}

sub PrintResults {
    my ( $self ) = @_;
    my $id = ident $self;

    while ( my ( $seq, $rsir ) = each %{ $results_by_sequence_of{$id} } ) {
        print '=' x 20, "\n", $seq, "\n\n";
        $rsir->DisplayStatus();
    }
}

1;

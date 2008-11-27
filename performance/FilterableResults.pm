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

    $result_set_of{$id}    = $opts_ref->{result_set};
    $filtered_data_of{$id} = [ @{ $result_set_of{$id}->get_data() } ];

    $filters_of{$id} = $opts_ref->{filters} || [];
    for my $filter ( @{ $filters_of{$id} } ) {
        $self->ApplyFilter($filter);
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
    else {
        die "Unknown filter $name";
    }
}

sub FilterFeatures {
    my ( $self, $features ) = @_;
    my $id = ident $self;

    @{ $filtered_data_of{$id} } =
      grep { FilterableResultSets::NormalizeFeatures( $_->get_features() ) eq $features }
      @{ $filtered_data_of{$id} };
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

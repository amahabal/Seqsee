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
use lib 'performance';
use Smart::Comments;
use IO::Prompt;

use FilterableResultSets;

use Getopt::Long;
my %options;
GetOptions \%options, "filename=s";

my $FRS =
  new FilterableResultSets( { sequences_filename => $options{filename} } );

$FRS->PrintSummary();
$FRS->PrintResults();

my %PossibleGraphTypes = ( AllData => 1 );
if ( $FRS->HasMultipleVersions() ) {
    $PossibleGraphTypes{CompareVersions} = 1;
    $PossibleGraphTypes{FilterData}      = 1;
}

if ( $FRS->HasMultipleFeatureSets() ) {
    $PossibleGraphTypes{CompareFS}  = 1;
    $PossibleGraphTypes{FilterData} = 1;
}

my $graph_type;
if ( 1 < keys %PossibleGraphTypes ) {
    $graph_type =
      prompt( -p => 'Type of graph: ', -m => [ keys %PossibleGraphTypes ] );
}
else {
    $graph_type = ( keys %PossibleGraphTypes )[0];
}

if ( $graph_type eq 'AllData' ) {
    DrawGraph( { sets => { All => $FRS->get_unfiltered_result_sets, } } );
}
elsif ( $graph_type eq 'CompareVersions' ) {
    my @versions = @{ $FRS->get_versions_in_data() };
    say "Available versions: ", join( ', ', @versions );
    my $how_many_clusters = prompt( "How many clusters? ", "-i" );
    my %sets;
    my @sets;
    for ( my $i = 1 ; $i <= $how_many_clusters ; ++$i ) {
        say "Cluster #$i:";
        my $minv = prompt( 'minimum version: ', -m => \@versions );
        my $maxv = prompt( 'maximum version: ', -m => \@versions );
        my $filter = [ 'version', $minv, $maxv ];
        my $name =
          ( $minv eq $maxv ) ? "version $minv" : "versions $minv-$maxv";
        push @sets, $name;
        $sets{$name} = FilterableResults->new(
            {
                result_set => $FRS,
                filters    => [$filter]
            }
        );
        $sets{$name}->PrintResults();
    }
    DrawGraph(
        {
            sets      => \%sets,
            set_order => \@sets,
        }
    );
}

sub DrawGraph {
    my ($opts_ref) = @_;
    my %sets = %{ $opts_ref->{sets} };
    my @sets;

    if ( 1 == keys %sets ) {
        @sets = keys %sets;
    }
    else {
        @sets = @{ $opts_ref->{set_order} };
        unless ( join( '+', sort @sets ) eq join( '+', sort keys %sets ) ) {
            die "set_order does not match sets";
        }
    }
    my @filtered_results = @sets{@sets};
    my @filtered_results_subindexed_by_seq =
      map { $_->get_results_by_sequence } @filtered_results;

    my @sequences_of_interest =
      @{ $filtered_results[0]->get_result_set()->get_sequences_to_track_aref()
      };

    open my $OUT, '>', "/tmp/graph.perf";
    say {$OUT} "title=$opts_ref->{title}";
    say {$OUT} "=norotate";
    say {$OUT} "";
    say {$OUT} "=cluster;", join( ';', @sets );
    say {$OUT} "=table";
    my $counter = 'a';
    for my $seq (@sequences_of_interest) {
        my @times =
          map { $_->{$seq}->get_avg_time_to_success() }
          @filtered_results_subindexed_by_seq;
        my @counts =
          map { $_->{$seq}->get_successful_count() }
          @filtered_results_subindexed_by_seq;

#my @times = map { $_->{$seq}->get_success_percentage() } @filtered_results_subindexed_by_seq;
        say {$OUT}
          join( ' ', $counter . ':' . join( ',', @counts ) , @times );
        $counter++;
    }

    close $OUT;
    my $outfile = '/tmp/out.eps';
    system( 'perl performance/bargraph.pl -eps /tmp/graph.perf > ' . $outfile );
    system( 'gv', $outfile );
}


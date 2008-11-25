use 5.10.0;

package ResultSetOfIndividualRuns;
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
my %results_of : ATTR(:name<results>);
my %successful_count_of :ATTR(:get<successful_count> :set<successful_count>);

my %vector_of_successful_of :
  ATTR(:get<vector_of_successful> :set<vector_of_successful>);
my %avg_time_to_success_of :
  ATTR(:get<avg_time_to_success> :set<avg_time_to_success>);
my %sdv_time_to_success_of :
  ATTR(:get<sdv_time_to_success> :set<sdv_time_to_success>);
my %success_percentage_of :
  ATTR(:get<success_percentage> :set<success_percentage>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $results_of{$id} = $opts_ref->{results};
    my @results = @{ $results_of{$id} };

    unless (@results) {
        $successful_count_of{$id} = 0;
        $avg_time_to_success_of{$id} = 0;
        $sdv_time_to_success_of{$id} = 0;
        $success_percentage_of{$id} = 0;
        return;
    }

    my @successful =
      grep { $_->get_status()->IsSuccess() } @results;
    my $vector = $vector_of_successful_of{$id} =
      vector( map { $_->get_steps() } @successful );

    $successful_count_of{$id} = scalar(@successful);
    $avg_time_to_success_of{$id} = 0 + mean($vector);
    $sdv_time_to_success_of{$id} = 0 + stddev($vector);
    $success_percentage_of{$id} = 100 * scalar(@successful) / scalar(@results);

}

sub DisplayStatus {
    my ($self)  = @_;
    my $id      = ident $self;
    my @results = @{ $results_of{$id} };
    my %count;
    for my $res (@results) {
        $count{$res->get_status()->get_status_string()}++;
    }
    print "\n";
    while (my($k, $v) = each %count ){
        print "$k\t=>$v\n";
    }
    
    print $success_percentage_of{$id}, '%', "averaging $avg_time_to_success_of{$id} steps", "\n";
}

1;

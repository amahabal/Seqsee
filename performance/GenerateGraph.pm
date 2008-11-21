use 5.10.0;

package GenerateGraph;

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
my %cluster_by_of : ATTR(:name<cluster_by>);
my %data_sets_of : ATTR(:name<data_sets>);
my %title_of : ATTR(:name<title>);

sub Generate {
    my ( $self, $outfilename ) = @_;

}

sub AddDataSet {
    my ( $self, $data_set ) = @_;

}


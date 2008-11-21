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

my $FRS = new FilterableResultSets(
    { sequences_filename => 'performance/TestSets/input_size2' } );

$FRS->PrintSummary();
$FRS->PrintResults();

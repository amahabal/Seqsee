use 5.10.0;
use strict;

use lib 'genlib';
use ResultOfTestRun;
use Global;
use List::Util qw{min max sum};
use Time::HiRes qw{time};
use Getopt::Long;
use Storable;

use File::Slurp;

my $text = read_file($ARGV[0]);
my $result_set = Storable::thaw($text);

say "Times: ", join(";", @{$result_set->get_times()});
say "Rates: ", join(";", @{$result_set->get_rate()});
say "Terms: ", $result_set->get_terms();
say "Features: ", $result_set->get_features();
say "Results: ", join(';', map { Storable::thaw($_)->get_status()->get_status_string } @{$result_set->get_results});

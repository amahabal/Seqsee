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

for my $filename (<performance/data/*>) {
    say "===========";
    my $text = read_file($filename);
    my $result_set = Storable::thaw($text);

    say "Version:  ", $result_set->get_version();
    say "Times: ", join(";", @{$result_set->get_times()});
    say "Rates: ", join(";", @{$result_set->get_rate()});
    say "Terms: ", $result_set->get_terms();
    say "Features: ", $result_set->get_features();
    say "Results: ", join(';', map { Storable::thaw($_)->get_status()->get_status_string } @{$result_set->get_results});
    say "Steps: ",  join(';', map { Storable::thaw($_)->get_steps() } @{$result_set->get_results});
}

use 5.10.0;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Getopt::Long;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Std;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES

# Do this to load seqsee.
use lib 'genlib';
use ResultOfTestRun;

use Perf::TestSequence;
use Perf::Version;
use Perf::FeatureSet;
use Perf::AllCollectedData;
use Perf::Figure::Specification;
use Perf::Figure::SequenceToDraw;
use Perf::Figure::SequenceToChart;
use Perf::Figure::Cluster;
use Perf::BarChart;
use Perf::CollatedData;

my $AllData = Perf::AllCollectedData->new();

for my $filename (<Perf/FigureSpecs/*>) {
    say "Starting $filename";
    eval {
        my $Spec = Perf::Figure::Specification->new_from_specfile(
            {
                all_read_data => $AllData,
                specfile      => $filename,
            }
        ) or confess $!;
        say "Read Spec for $filename";
        say $Spec->_DUMP();
        my $outfile = $filename . '.eps';
        $outfile =~ s#FigureSpecs#FigureOutput#;
        Perf::BarChart->Plot( { spec_object => $Spec, outfile => $outfile } );
        say "Finished plot for $filename";
    };
    say "Finished $filename: $!";
}


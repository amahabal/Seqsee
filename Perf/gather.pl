use 5.10.0;
## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use Carp;
use Class::Multimethods;
use Config::Std;
use English qw(-no_match_vars );
use Exception::Class;
use File::Slurp;
use Getopt::Long;
use IO::Prompt;
use List::Util qw{min max sum first};
use Memoize;
use Scalar::Util qw(blessed);
use Smart::Comments '###';
use Sort::Key;
use Storable;
use Time::HiRes;
use strict;
use warnings;

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
use Perf::GatherDataFor;


my $AllData = Perf::AllCollectedData->new();
my $filename = 'Perf/Chapter3Config/Distractors/all';
my $Spec    = Perf::Figure::Specification->new_from_specfile(
    {
        all_read_data => $AllData,
        specfile      => $filename,
    }
) or confess $!;

Perf::GatherDataFor->Gather({spec => $Spec, min_result_set => 20});

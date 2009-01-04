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

use Getopt::QuotedAttribute;
our $FLAG_filename : Getopt("filename=s" => "(Required) Chart specification file for which to gather data by running Seqsee.");
$FLAG_filename // Getopt::QuotedAttribute::usage("Missing required argument filename");

our $FLAG_times : Getopt("times=i" => "(Required) Run Seqsee enough times so that for each sequence in file, it has been run at least this many times.");
$FLAG_times // Getopt::QuotedAttribute::usage("Missing required argument times");

confess "$FLAG_filename does not exist!" unless -e $FLAG_filename;

my $AllData = Perf::AllCollectedData->new();
my $Spec    = Perf::Figure::Specification->new_from_specfile(
    {
        all_read_data => $AllData,
        specfile      => $FLAG_filename,
    }
) or confess $!;

Perf::GatherDataFor->Gather(
    { spec => $Spec, min_result_set => $FLAG_times } );

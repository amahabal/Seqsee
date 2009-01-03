#!/usr/local/bin/perl -w
use 5.10.0;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES

use File::Path;
use File::Spec;

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

use Getopt::QuotedAttribute;
our $FLAG_indir : Getopt("indir=s" => "(Optional) Input directory");
our $FLAG_outdir : Getopt("outdir=s" => "(Optional) Output directory");
Getopt::QuotedAttribute::usage(
    "Both --indir and --outdir should be present, or both absent.")
  if ( ( $FLAG_indir and not $FLAG_outdir )
    or ( $FLAG_outdir and not $FLAG_indir ) );

$FLAG_indir //= "Perf/Chapter3Config";
$FLAG_outdir //= "Perf/Chapter3Figures";


my $AllData = Perf::AllCollectedData->new();

CreateFigures(
    {
        input_directory => $FLAG_indir,
        output_diretory => $FLAG_outdir
    }
);

## Method ######################
#  Name             : CreateFigures
#  Returns          : -
#  Parameters       : input_directory, output_diretory
#  Params via href  : Yes
#  Purpose          : Convert figure specification into eps files.
##
#  Throws           : no exceptions

sub CreateFigures {
    my ($opts_ref) = @_;
    my $input_directory = $opts_ref->{input_directory}
      // confess "Missing required argument 'input_directory'";
    my $output_diretory = $opts_ref->{output_diretory}
      // confess "Missing required argument 'output_diretory'";

    for my $filename (<$input_directory/*>) {
        my ( $volume, $dir, $just_filename ) = File::Spec->splitpath($filename);
        ## vdf:$volume, $dir, $just_filename
        my $corresponding_filename =
          File::Spec->catfile( $output_diretory, $just_filename );

        if ( -d $filename ) {
            unless ( -e $corresponding_filename ) {
                mkpath($corresponding_filename);
            }
            CreateFigures(
                {
                    input_directory => $filename,
                    output_diretory => $corresponding_filename
                }
            );
        }
        else {
            my $Spec = Perf::Figure::Specification->new_from_specfile(
                {
                    all_read_data => $AllData,
                    specfile      => $filename,
                }
            ) or confess $!;
            say "Read Spec for $filename";

            my $outfile2 = $corresponding_filename . '_no_ovals.eps';
            Perf::BarChart->Plot(
                {
                    spec_object => $Spec,
                    outfile     => $outfile2,
                    no_ovals    => 1
                }
            );
            say "Finished plot for $filename";

            if ( $Spec->get_split_chart() ) {
                my $outfile_seq = $corresponding_filename . '_seq.eps';
                my $outfile_bar = $corresponding_filename . '_bar.eps';
                Perf::BarChart->Plot(
                    {
                        spec_object => $Spec,
                        outfile     => $outfile_seq,
                        no_chart    => 1
                    }
                );
                Perf::BarChart->Plot(
                    {
                        spec_object => $Spec,
                        outfile     => $outfile_bar,
                        no_seq      => 1
                    }
                );

            }
            else {
                my $outfile = $corresponding_filename . '.eps';
                Perf::BarChart->Plot(
                    { spec_object => $Spec, outfile => $outfile } );

                say "Finished second plot, wrote to $outfile2";

            }

            # say $Spec->_DUMP();

        }
    }
}

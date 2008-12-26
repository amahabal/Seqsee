package Perf::GatherDataFor;
use 5.10.0;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use Carp;
use Class::Multimethods;
use Class::Std;
use Config::Std;

#use Class::Std::Storable;
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

sub Gather {
    my ( $package, $opts_ref ) = @_;
    my $spec = $opts_ref->{spec} // confess "Missing required argument 'spec'";
    my $min_result_set = $opts_ref->{min_result_set}
      // confess "Missing required argument 'min_result_set'";

    $spec->isa("Perf::Figure::Specification")
      or confess "Expected \$spec to be of type Perf::Figure::Specification."
      . "Instead, it is of type "
      . ref($spec);

    my $type = $spec->get_figure_type();
    my @arg_sets_for_harness;

    if ( $type eq 'NonLTM' ) {
        @arg_sets_for_harness =
          Get_Arg_Set_for_NonLTM( $spec, $min_result_set );
    }

}

sub Get_Arg_Set_for_NonLTM {
    my ( $spec, $min_result_set ) = @_;
    my @sequences_to_chart = @{ $spec->get_sequences_to_chart };
    my @clusters           = @{ $spec->get_clusters };

    for my $seq_to_chart (@sequences_to_chart) {
        my $sequence        = $seq_to_chart->get_sequence();
        my $data_by_cluster = $seq_to_chart->get_data_indexed_by_cluster;

        for my $cluster (@clusters) {
            next if $cluster->get_source() eq 'Human';

            my $data       = $data_by_cluster->{$cluster};
            my $data_count = $data->get_total_count;

            if ( $data_count >= $min_result_set ) {
                say "I have enough data for $cluster for $sequence";
            }
            else {
                say "I need more data for ",
                  $cluster->_DUMP(), " for ", $sequence->_DUMP();

                my $sequence_string = $sequence->ArgumentForSeqsee();
                say "seq: $sequence_string";
                RunSeqseeOn(
                    {
                        times_to_run  => $min_result_set - $data_count,
                        sequence      => $sequence->get_revealed(),
                        continuation  => $sequence->get_all_unrevealed(),
                        max_steps     => 25000,
                        min_extension => 3,
                        max_false     => 3,
                        tempfilename  => 'temp',
                        feature_set   => '',                                #xxx
                        code_version  => Perf::Version->GetVersionOfCode,
                        outputdir     => 'Perf/data/Seqsee',
                    }
                  )

            }

        }
    }

}

sub RunSeqseeOn {
    my ( $opts_ref ) = @_;
    my $times_to_run = $opts_ref->{times_to_run}
      // confess "Missing required argument 'times_to_run'";
    my $sequence = $opts_ref->{sequence}
      // confess "Missing required argument 'sequence'";
    my $continuation = $opts_ref->{continuation}
      // confess "Missing required argument 'continuation'";
    my $max_steps = $opts_ref->{max_steps}
      // confess "Missing required argument 'max_steps'";
    my $min_extension = $opts_ref->{min_extension}
      // confess "Missing required argument 'min_extension'";
    my $max_false = $opts_ref->{max_false}
      // confess "Missing required argument 'max_false'";
    my $tempfilename = $opts_ref->{tempfilename}
      // confess "Missing required argument 'tempfilename'";
    my $feature_set = $opts_ref->{feature_set}
      // confess "Missing required argument 'feature_set'";
    my $code_version = $opts_ref->{code_version}
      // confess "Missing required argument 'code_version'";
    my $outputdir = $opts_ref->{outputdir}
      // confess "Missing required argument 'outputdir'";
    my @selected_feature_set = split( ';', $feature_set );

    my @cmd;
    if ( $OSNAME eq 'MSWin32' ) {
        @cmd = ( 'c:\perl\bin\perl', 'util/RunTestOnce.pl' );
    }
    else {
        @cmd = ( 'perl', 'util/RunTestOnce.pl' );
    }

    push @cmd,
      (
        qq{--seq="$sequence"},      qq{--continuation="$continuation"},
        qq{--max_steps=$max_steps}, qq{--min_extension=$min_extension},
        qq{--max_false=$max_false}, qq{--tempfilename=$tempfilename},
        @selected_feature_set,
      );

    my ( @EFFECTIVE_CODELET_RATE, @RESULTS, @WALLCLOCK_TIME );
    for ( 1 .. $times_to_run ) {
        unlink $tempfilename;
        my $time_before = time();
        system @cmd;
        my $time_taken = time() - $time_before;
        push @WALLCLOCK_TIME, $time_taken;

        open( my $RESULT, '<', $tempfilename )
          or confess "Unable to open file >>$tempfilename<<";
        my $result_str = join( '', <$RESULT> );
        push @RESULTS, $result_str;

        my $effective_codelet_rate =
          Storable::thaw($result_str)->get_steps() / $time_taken;
        push @EFFECTIVE_CODELET_RATE, $effective_codelet_rate;
    }
    my $Results_of_test_runs = ResultsOfTestRuns->new(
        {
            times    => \@WALLCLOCK_TIME,
            results  => \@RESULTS,
            rate     => \@EFFECTIVE_CODELET_RATE,
            terms    => "$sequence|$continuation",
            features => $feature_set,
            version  => $code_version,
        }
    );

    my $string_to_write = Storable::freeze($Results_of_test_runs);
    my $filename = "$outputdir/" . join( '', localtime(), rand() );
    open my $OUT, '>', $filename or die "Could not open $filename";
    print {$OUT} $string_to_write;
    close $OUT;
}

1;

__END__


=head1 NAME

GatherDataFor - Run Seqsee Multiple times on sequences mentioned in a spec file.

=head1 VERSION

This document describes GatherDataFor for revision $Revision$

=head1 SYNOPSIS

GatherDataFor->Gather({spec => $spec_object, min_result_set => 30});
  
=head1 DESCRIPTION

Given a specfile (from which charts are generated for the dissertation), locate
sequences for which data is needed, and run Seqsee enough times to collect such
data.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

GatherDataFor requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Abhijit Mahabal  C<< amahabal@gmail.com >>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

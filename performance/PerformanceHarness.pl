use 5.10.0;
use strict;

use lib 'genlib';
use Test::Seqsee;
use Global;
use List::Util qw{min max sum};
use Time::HiRes qw{time};
use Getopt::Long;
use Storable;

my $StartTime = time();

my %options = (
    f => sub {
        my ( $ignored, $feature_name ) = @_;
        print "$feature_name will be turned on\n";
        unless ( $Global::PossibleFeatures{$feature_name} ) {
            print "No feature $feature_name. Typo?\n";
            exit;
        }
        $Global::Feature{$feature_name} = 1;
    }
);
GetOptions( \%options, "times=i", "steps=i", "f=s", "filename=s", "outputdir=s",
    "code_version=s", 'tempfilename=s', );

my ( $times, $MaxSteps, $sequence_list_filename, $outputdir, $code_version,
    $tempfilename )
  = @options{ 'times', 'steps', 'filename', 'outputdir', 'code_version',
    'tempfilename' };
$sequence_list_filename //= 'config/sequence_list_for_multiple';
$outputdir    // confess "Need outputdir";
$code_version // confess "Need code_version";
$tempfilename // confess "Need tempfilename";

my @selected_feature_set = map { "-f=$_" } keys %Global::Feature;

open my $LIST, '<', $sequence_list_filename or die "Failed to open list";
my @sequence_list = <$LIST>;
close $LIST;
@sequence_list = grep { $_ } map { s#^\s*##; s#\s*$##; $_ } @sequence_list;

for my $terms (@sequence_list) {
    say "================== $terms";
    my ( $seq, $continuation ) = split( /\|/, $terms );
    my @cmd;
    if ( $OSNAME eq 'MSWin32' ) {
        @cmd = ( 'c:\perl\bin\perl', 'util/RunTestOnce.pl' );
    }
    else {
        @cmd = ( 'perl', 'util/RunTestOnce.pl' );
    }

    push @cmd,
      (
        qq{--seq="$seq"},         qq{--continuation="$continuation"},
        qq{-max_steps=$MaxSteps}, qq{--min_extension=3},
        qq{--max_false=3},        qq{-tempfilename=$tempfilename},
        @selected_feature_set,
      );
    my ( @WALLCLOCK_TIME, @RESULTS, @EFFECTIVE_CODELET_RATE );
    for ( 1 .. $times ) {
        say "++++++ $_";

        # print ">>@cmd<<\n";

        unlink $tempfilename;
        my $time_before = time();
        system @cmd;
        my $time_taken = time() - $time_before;
        push @WALLCLOCK_TIME, $time_taken;

        open( my $RESULT, '<', $tempfilename )
          or confess "Unable to open file >>$tempfilename<<";
        my $result_str = join( '', <$RESULT> );

        #my $result_object = Storable::thaw($result_str)
        #    or confess "Unable to thaw: >>$result_str<<!!";
        push @RESULTS, $result_str;

        my $effective_codelet_rate =
          Storable::thaw($result_str)->get_steps() / $time_taken;
        push @EFFECTIVE_CODELET_RATE, $effective_codelet_rate;
        print "RESULT ADDED\n";
    }
    my $Results_of_test_runs = ResultsOfTestRuns->new(
        {
            times    => \@WALLCLOCK_TIME,
            results  => \@RESULTS,
            rate     => \@EFFECTIVE_CODELET_RATE,
            terms    => $terms,
            features => join( ';', @selected_feature_set ),
            version  => $code_version,
        }
    );

    my $string_to_write = Storable::freeze($Results_of_test_runs);
    my $filename = "$outputdir/" . join( '', localtime(), rand() );
    open my $OUT, '>', $filename or die "Could not open $filename";
    print {$OUT} $string_to_write;
    close $OUT;
}


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

my ( $times, $MaxSteps, $config_filename, $outputdir, $code_version,
    $tempfilename )
  = @options{ 'times', 'steps', 'filename', 'outputdir', 'code_version',
    'tempfilename' };
$config_filename // confess "Need filename";
$outputdir       // confess "Need outputdir";
$code_version    // confess "Need code_version";
$tempfilename    // confess "Need tempfilename";

$Global::Feature{LTM}      = 1;
$Global::Feature{LTM_expt} = 1;
my @selected_feature_set = map { "-f=$_" } keys %Global::Feature;

read_config $config_filename, my %ExptConfig;

sub ClearMemory {
    open my $MEMORY_HANDLE, '>', 'memory_dump.dat';
    print {$MEMORY_HANDLE} ' ';
    close $MEMORY_HANDLE;
}

{
    my $save_location = '/tmp/memory_dump.dat.save';

    sub SaveMemory {
        system "mv memory_dump.dat $save_location";
    }

    sub RestoreMemory {
        system "mv $save_location memory_dump.dat";
    }
}

if ( exists $ExptConfig{Context} ) {
    my $seq = $ExptConfig{Context}{seq} or confess "Context, but no seq";
    my $test_seq = $ExptConfig{Sequence}{seq}
      or confess "Missing test sequence!";

    ClearMemory();
    RunAndIgnore( { times => 10, seq => $seq } );
    SaveMemory();

    RunAndRemember(
        { seq => $test_seq, restore_memory => 1, context => $seq } );
}
else {
    my $test_seq = $ExptConfig{Sequence}{seq}
      or confess "Missing test sequence!";
    for ( 1 .. 10 ) {
        ClearMemory();
        RunAndRemember(
            { seq => $test_seq, restore_memory => 0, context => '' } );
    }
}

sub RunAndIgnore {
    my ($options_ref) = @_;
    my ( $times, $seq ) = ( $options_ref->{times}, $options_ref->{seq} );
    my ( $seq, $continuation ) = split( /\|/, $seq );
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
        qq{--max_steps=$MaxSteps}, qq{--min_extension=3},
        qq{--max_false=3},        qq{-tempfilename=$tempfilename},
        @selected_feature_set,
      );
    my ( @WALLCLOCK_TIME, @RESULTS, @EFFECTIVE_CODELET_RATE );

    for ( 1 .. $times ) {
        say "++++++ $_ for [$seq]";
        unlink $tempfilename;
        my $time_before = time();
        system @cmd;
        my $time_taken = time() - $time_before;
    }
}

sub RunAndRemember {
    my ($options_ref) = @_;
    my %options = %$options_ref;
    my ( $terms, $restore_memory, $context ) =
      @options{qw{seq restore_memory context}};

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
        qq{--max_steps=$MaxSteps}, qq{--min_extension=3},
        qq{--max_false=3},        qq{-tempfilename=$tempfilename},
        @selected_feature_set,
      );
    my ( @WALLCLOCK_TIME, @RESULTS, @EFFECTIVE_CODELET_RATE );
    for ( 1 .. 10 ) {
        say "++++++ $_ for [$seq]";

         print ">>@cmd<<\n";

        unlink $tempfilename;
        my $time_before = time();
        RestoreMemory() if $restore_memory;
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
            times         => \@WALLCLOCK_TIME,
            results       => \@RESULTS,
            rate          => \@EFFECTIVE_CODELET_RATE,
            terms         => $terms,
            context       => $context,
            is_ltm_result => 1,
            features      => join( ';', @selected_feature_set ),
            version       => $code_version,
        }
    );

    my $string_to_write = Storable::freeze($Results_of_test_runs);
    my $filename = "$outputdir/" . join( '', localtime(), rand() );
    open my $OUT, '>', $filename or die "Could not open $filename";
    print {$OUT} $string_to_write;
    close $OUT;
}


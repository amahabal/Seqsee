# runNoTk: Running seqsee in a text mode

# External libraries
use warnings;
use strict;
use Getopt::Long;
use blib;

# Seqsee libraries
use SLog;
use SUtility;
use SApp;
use Sconsts;
use SCodelet;
use SCoderack;
use SWorkspace;
use SElement;
use SNet;

our $logging = 1;
GetOptions("seed=s"  => \$SApp::RandomSeed,
	   "steps=i" => \$SApp::MaxSteps,
	   "log!"    => \$logging,
	  );


$SApp::RandomSeed = int(rand() * 32000) unless $SApp::RandomSeed;
srand($SApp::RandomSeed);

SLog->init($logging);
our $TopLogger = Log::Log4perl->get_logger('');


### Initialize Display
##    SDisplay->init("SDisplay::simple");
### Initialize Fascinations
##    SFascination->init("SFascination::slipnet")

our @Seq = @ARGV;
SApp->init(@Seq);

our $CurrentCodelet       = undef;
our $CurrentCodeletFamily = undef;
our $CurrentEpoch         = 0;

my $starttime = time;

#### MAIN LOOP:

for (1..$SApp::MaxSteps) {
  if ($_ % 100 == 0) {
    my $elasped = time() - $starttime;
    print "Finished $_ codelets in $elasped seconds\n";
  }
  Step();
}

sub Step{
  $CurrentEpoch++; # XXX: Is this the right place to update?
  SApp->hooks_before_each_step();

  $CurrentCodelet = SCoderack->choose_codelet;

  if (defined $CurrentCodelet) {
    $CurrentCodeletFamily = $CurrentCodelet->[0];
    $CurrentCodelet->run();
  } else {
    $TopLogger->warn("\n\n[$CurrentEpoch] The coderack was empty!");
  }
  SApp->hooks_after_each_step();
}

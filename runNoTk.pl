# runNoTk: Running seqsee in a text mode

# External libraries
use warnings;
use strict;
use Getopt::Long;
use blib;

# Seqsee libraries
use SUtility;
use SApp;
use Sconsts;
use SCodelet;
use SCoderack;
use SWorkspace;
use SElement;
use SNet;


GetOptions("seed=s"  => \$SApp::RandomSeed,
	   "steps=i" => \$SApp::MaxSteps,
	  );

$SApp::RandomSeed = int(rand() * 32000) unless $SApp::RandomSeed;
srand($SApp::RandomSeed);

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
  $CurrentEpoch++;
  SApp->hooks_before_each_step();

  $CurrentCodelet = SCoderack->choose_codelet;

  if (defined $CurrentCodelet) {
    $CurrentCodeletFamily = $CurrentCodelet->[0];
    $CurrentCodelet->run();
  }
  SApp->hooks_after_each_step();
}

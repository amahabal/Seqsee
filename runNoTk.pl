# runNoTk: Running seqsee in a text mode

# External libraries
use warnings;
use strict;
use Getopt::Long;
use blib;

# Seqsee libraries
use SApp;
use Sconsts;
use SCodelet;
use SCoderack;
use SWorkspace;
use SElement;
use SNet;

our $RandomSeed = undef;
our $MaxSteps    = 1000;

GetOptions("seed=s"  => \$RandomSeed,
	   "steps=i" => \$MaxSteps,
	  );

$RandomSeed = int(rand() * 32000) unless $RandomSeed;

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

for (1..$MaxSteps) {
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

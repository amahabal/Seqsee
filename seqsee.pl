# seqsee: running seqsee in any mode!

use blib;
use strict;
use Tk;
use Tk::Getopt;

our @option_table;
our $opt;
our %options;

BEGIN {
  @option_table = 
    (
     [ 'seed', '=i', undef, 
       nogui => 1,
     ],

     [ 'tk', '!', 1,
       label => "Use Tk?",
       help  => "Should a GUI be used?",
     ],

     [ 'steps', '=i', 10,
       label => "Maximum number of steps",
       help  => "The maximum number of steps the program will run",
     ],

     ['log', '!', 1,
      label => "Logging",
      help  => "Should logging be on or off?"
     ],

    );

  $opt = new Tk::Getopt(-opttable => \@option_table,
			-options  => \%options,
			-filename => "config",
		       );

  $opt->set_defaults;
  $opt->load_options;
  $options{seed} = int( rand() * 32000 );
  $opt->get_options;
}

use constant GUI     => $options{tk};
use constant LOGGING => $options{log};

use SLog;

BEGIN{
  SLog->init(LOGGING);
}

use constant LOGGER => Log::Log4perl->get_logger('');

##########################################
# That handles the GUI and Logging constants
# Now to the actual work

use Suseorder;

SFascination->load("SFasc::simple");

our @Seq = @ARGV;
SApp->init(@Seq);

our $CurrentCodelet       = undef;
our $CurrentCodeletFamily = undef;
our $CurrentEpoch         = 0;

my $starttime = time;

if (GUI) {
  MainLoop;
} else {
  for (1 .. $options{steps}) {
    if ($_ % 100 == 0) {
      my $elasped = time() - $starttime;
      print "Finished $_ codelets in $elasped seconds\n";
    }
    Step();
  }
}

sub Step{
  $CurrentEpoch++;
  SApp->hooks_before_each_step();
  $CurrentCodelet = SCoderack->choose_codelet;

  if (defined $CurrentCodelet) {
    $CurrentCodeletFamily = $CurrentCodelet->[0];
    $CurrentCodelet->run();
  } else {
    LOGGER->warn("\n\n[$CurrentEpoch] The coderack was empty!");
  }
  SApp->hooks_after_each_step;
}

use strict;
use blib;

use Config::Std;
use Getopt::Long;

use S;
use SUtil;
use Seqsee;

use Smart::Comments;
use List::Util qw(min);
use UNIVERSAL::require;
use Sub::Installer;
use IO::Prompt;
use English qw(-no_match_vars );

# Defaults for configuration: used if not spec'd in config file
#   or on the command line.
my %DEFAULTS 
    = ( seed => int( rand() * 32000 ),
        update_interval => 0, # If default used, carps when interactive 
            );

my $Steps_Finished = 0;

my $OPTIONS_ref = _read_config_and_commandline();
INITIALIZE();
GET_GOING(); # Potentially "infinite" loop

#### method INITIALIZE
# usage          :INITIALIZE()
# description    :pulls all the pieces in, initializes them etc. 
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub INITIALIZE{

    Seqsee->initialize_codefamilies();

    # Initialize logging
    SLog->init( $OPTIONS_ref );

    # Initialize display
    init_display( $OPTIONS_ref );

    # Initialize Coderack
    SCoderack->clear(); SCoderack->init( $OPTIONS_ref );

    # Initialize Stream
    SStream->clear(); SStream->init( $OPTIONS_ref );

    # Initialize Workspace
    SWorkspace->clear(); SWorkspace->init( $OPTIONS_ref );


}


#### method GET_GOING
# usage          :GET_GOING( $OPTIONS_ref )
# description    :what happens depends on whether interaction is turned on, and whether Tk is turned on.
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub GET_GOING{
    # This should be the last "setup" function: the real work begins here. Don't expect this to ever return.
    my $tk = $OPTIONS_ref->{tk};
    my $interactive = $OPTIONS_ref->{interactive};
    if ( $interactive ) {
        if ( $tk ) {
            MainLoop();
        } else {
            TextMainLoop();
        }
    } else {
        Interaction_continue();
    }
}




#### method _read_config_and_commandline
# usage          :
# description    :Reads the configuration (conf/seqsee.conf), updates what it sees using the commandline arguments, sets defaults, and returns the whole thing in a HASH
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub _read_config_and_commandline{
    my $RETURN_ref = {};
    read_config 'config/seqsee.conf' => my %config;
    my %options;
    GetOptions( \%options,
                "seed=i",
                "log!",
                "tk!",
                "seq=s",
                "update_interval=i",
                "interactive!",
                    );
    for (qw{seed log tk seq max_steps 
            interactive update_interval}) {
        my $val 
            = exists($options{$_})        ? $options{$_} :
              exists($config{seqsee}{$_}) ? $config{seqsee}{$_} :
              exists($DEFAULTS{$_})       ? $DEFAULTS{$_} :
                  die "Option '$_' not set either on command line, conf file or defauls";
        $RETURN_ref->{$_} = $val;
    }

    # SANITY CHECKING: SEQ
    my $seq = $RETURN_ref->{seq};
    unless ($seq =~ /^[\d\s,]+$/) {
        die "The option --seq must be a space or comma separated list of integers";
    }
    for ($seq) { s/^\s*//; s/\s*$//; }
    my @seq = split(/[\s,]+/, $seq);
    $RETURN_ref->{seq} = [ @seq ];

    # SANITY CHECKING: interactive
    if ($RETURN_ref->{tk} and not($RETURN_ref->{interactive})) {
        print "Using Tk forces interactivity! Reading your mind...\n";
        $RETURN_ref->{interactive} = 1;
    }

    # SANITY CHECKING: update_interval
    if ($RETURN_ref->{interactive} 
            and not($RETURN_ref->{update_interval})) {
        die "Seqsee is being used interactively: absolutely must have the update interval: it cannot use the value $RETURN_ref->{update_interval}";
    }

    return $RETURN_ref;
}

#### method Interaction_step_n
# usage          :
# description    :Takes upto n steps
# argument list  :n, and update_after
# return type    :true if the program should stop
# context of call: scalar
# exceptions     :

sub Interaction_step_n{
    my $opts_ref = shift;

    my $n = $opts_ref->{n} or die "Need n";
    $n = min( $n, 
              $OPTIONS_ref->{max_steps} - $Steps_Finished );
    return 1 unless $n; # i.e, okay to stop now!

    my $update_after = $opts_ref->{update_after} || $n;

    my $change_after_last_display = 0;#to prevent repeats at end
    my $program_finished = 0;

    for my $steps_executed (1..$n) {
        $program_finished = Seqsee_Step();
        $change_after_last_display = 1;
        
        if (not ($steps_executed % $update_after)) {
            update_display();
            $change_after_last_display = 0;
        }
        last if $program_finished;
    }
    
    update_display() if $change_after_last_display;
    return $program_finished;
}

#### method Interaction_continue
# usage          :
# description    :goes into a loop, taking one step at a time
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub Interaction_continue{
    return
        Interaction_step_n
            ( {
                n => $OPTIONS_ref->{max_steps},
                update_after => $OPTIONS_ref->{update_interval},
            });
}


#### method Interaction_step
# usage          :
# description    :A single step of interaction
# argument list  :
# return type    :True if program should stop
# context of call:
# exceptions     :

sub Interaction_step{
    return 
        Interaction_step_n( { n => 1,
                              update_after => 1,
                          });
}


#### method init_display
# usage          :
# description    :Initializes display related attributes, windows(if necessary) etc. Also pulls in the Tk modules if called for. Sets up update_display() as well.
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub init_display{
    my $tk = $OPTIONS_ref->{tk};

    if ($tk) {
        "Tk"->require();
        import Tk;
        $::MW = new MainWindow();

        my $update_display_sub = sub {
            print "Updated Tk display! (change me)\n";
        };
        "main"->install_sub( {update_display =>
                                  $update_display_sub
                                  });
    } else {
        my $update_display_sub = sub {
            print "Updated Tk display! (change me)\n";
        };
        "main"->install_sub( {update_display =>
                                  $update_display_sub
                                      });
    }
}


#### method TextMainLoop
# usage          :
# description    :Main interaction loop for text mode: just uses commands 's', 's \d+', 'c' and 'e'
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub TextMainLoop{
    while (my $line = prompt -require => { "Seqsee> " =>  qr{\S}},
           "Seqsee> ") {
        if ($line =~ m/^ \s* s \s*$/xi) {
            Interaction_step( { n => 1, update_after => 1 } );
        } elsif ( $line =~ m/^ \s* s \s* (\d+) \s* $/xi) {
            Interaction_step( { n => $1, 
                                update_after=> $OPTIONS_ref->{update_interval},
                            } );
        } elsif ( $line =~ m/^ \s* c \s* $/ix) {
            Interaction_continue();
        } elsif ($line =~ m/^ \s* e \s* $/ix) {
            if (prompt "Really quit? ", "-yn") {
                return;
            }
        } else {
            chomp($line);
            print "Unknown command '$line': should be s, s n, c or e\n";
        }
    }
}



#### method Seqsee_Step
# usage          :
# description    :One step of Seqsee execution. That involves pulling one codelet off the stack and seeing what happens, I think
# argument list  :
# return type    : true if prog finished, false o/w
# context of call:
# exceptions     :

sub Seqsee_Step{
    my $codelet = SCoderack->choose_codelet();
    ## $codelet
    unless ($codelet) {
        die "No codelet in coderack. Don't know what I should do here";
    }

    eval { $codelet->run() };
    if ($EVAL_ERROR) {
        my $err = $EVAL_ERROR;
        if (UNIVERSAL::isa($err, 'SErr::ProgOver')) {
            return 1; # i.e., program finished
        } else {
            ref $err ? $err->rethrow() : die $err;
        }
    }
    return; # false: so, the show must go on.
}

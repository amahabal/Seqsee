package Seqsee;
use S;
use version; our $VERSION = version->new( "0.0.3" );

use English qw(-no_match_vars);
use List::Util qw(min max);
use Carp;
use Smart::Comments;
use Config::Std;
use Getopt::Long;

sub run{
    my (@sequence) = @_;
    SWorkspace->clear(); SWorkspace->init(@sequence);
    SStream->clear();    SStream->init();
    SCoderack->clear();  SCoderack->init();

    _SeqseeMainLoop();

}


# method: initialize_codefamilies
#  loads up all the codefamilies. Their list occurs in SCF.list
#
# exceptions:
#     missing codefamily etc. 

sub initialize_codefamilies{
    use UNIVERSAL::require;
    open(IN, "SCF.list") or SErr::Code->throw("Could not open SCF.list");
    while (my $in = <IN>) {
        $in =~ s{#.*}{};
        $in =~ s#\s##g;
        next unless $in;
        $in->require or SErr::Code->throw($@ . "Required Codefamily '$in' missing");

        #unless (defined ${"$in"."::logger"}) {
        #    die"Error in processing codefamily '$in': It defines no variable \$logger\n";
        #}

        unless (UNIVERSAL::can($in, "run")) {
            SErr::Code->throw("Error in processing codefamily '$in': It does not define the method run()");
        }
    }
}



# method: initialize_thoughttypes
# 
sub initialize_thoughttypes{
    use UNIVERSAL::require;
    open(IN, "ThoughtType.list") 
        or SErr::Code->throw("Could not open SCF.list");
    while (my $in = <IN>) {
        $in =~ s{#.*}{};
        $in =~ s#\s##g;
        next unless $in;
        $in->require() or SErr::Code->throw("$@ Required Thoughtfamily '$in' missing");

        unless ( UNIVERSAL::can($in, "get_fringe") and 
                 UNIVERSAL::can($in, "get_extended_fringe") and
                 UNIVERSAL::can($in, "get_actions")
              ) {
            SErr::Code->throw("Error in processing thoughtfamily '$in': It does not define one of the following methods: get_fringe, get_extended_fringe, get_actions");
        }
    }
}

# method: do_background_activity

sub do_background_activity{
    SCoderack->add_codelet( SCodelet->new( "Reader",
                                           50, {}
                                               ));

}
sub already_rejected_by_user{
    my ( $aref ) = @_;
    my @a = @$aref;
    my $cnt = scalar @a;
    for my $i (0..$cnt-1) {
        my $substr = join(", ", @a[0..$i] );
        ## Chekin for user rejection: $substr
        return 1 if $::EXTENSION_REJECTED_BY_USER{$substr};
    }
    return 0;
}

# method: Seqsee_Step
# One step of Seqsee execution. 
# 
# Details:
#  Backround activity is things that should happen between steps, update activation etc. Done using a call to do_background_activity()
#
#  The call SCoderack->get_next_runnable() returns a codelet or a thought, taking into account whether a thought is scheduled, etc.
# 
#  If a thought is returned, we should call SStream->add_thought(), which, er, thinks the thought.
#
#  If it is a codelet, it should be executed, and its return value looked at: If the return value is a thought, that should also result in SStream->add_thought(), too.
# 
# Error Checking:
#   * If running a codelet, traps SErr::ProgOver and SErr::Think
#   * If running a thought, traps SErr::Think
#
# return value: 
#    true if prog finished

sub Seqsee_Step{
    $Global::Steps_Finished++;
    do_background_activity();

    ## $Global::Steps_Finished
    my $runnable = SCoderack->get_next_runnable();
    return unless $runnable; # prog not yet finished!

    eval {
        if ($runnable->isa("SCodelet")) {
            $::CurrentRunnableString = "SCF::". $runnable->[0];
            $runnable->run();
        } elsif ($runnable->isa("SThought")) {
            $::CurrentRunnableString = ref($runnable);
            ## $runnable
            SStream->add_thought( $runnable );
        } else {
            SErr::Fatal->throw("Runnable object is $runnable: expected an SThought or a SCodelet");
        }
    };

    if ($EVAL_ERROR) {
        my $err = $EVAL_ERROR;
        ## Caught an error: ref($err)
        if (UNIVERSAL::isa($err, 'SErr::ProgOver')) {
            return 1;
        }
        if (UNIVERSAL::isa($err, 'SErr::NeedMoreData') or
              UNIVERSAL::isa($err, 'SErr::ContinueWith')
                    ) {
            $err->payload()->schedule();
            return;
        }
        main::default_error_handler($err);        
    }
    return;
}


# method: Interaction_step_n
# Takes upto n steps
#
#    Updates display after update_after
#
#    usage:
#       Interaction_step_n( $options_ref )     
#
#    parameter list:
#        n - steps to take
#        update_after - update display every so many steps
#
#    return value:
#      bool, whether program has finished
#
#    possible exceptions:

sub Interaction_step_n{
    my $opts_ref = shift;
    ## In Interaction_step_n: $opts_ref

    my $n = $opts_ref->{n} or confess "Need n";
    $n = min( $n, 
              $opts_ref->{max_steps} - $Global::Steps_Finished );
    return 1 unless $n > 0; # i.e, okay to stop now!

    my $update_after = $opts_ref->{update_after} || $n;

    my $change_after_last_display = 0;#to prevent repeats at end
    my $program_finished = 0;

    STEP_LOOP: for my $steps_executed (1..$n) {
	$Global::Break_Loop = 0;

        ## Interaction_step_n executing step number: $steps_executed
        $program_finished = Seqsee_Step();
        ## Interaction_step_n finished step: $steps_executed 
        $change_after_last_display = 1;
        
        if (not ($steps_executed % $update_after)) {
            main::update_display();
            $change_after_last_display = 0;
        }
        last if $program_finished;
	last if $Global::Break_Loop;
    }
    
    main::update_display() if $change_after_last_display;
    return $program_finished;
}

# var: %DEFAULTS
# Defaults for configuration
#
# used if not spec'd in config file or on the command line.
my %DEFAULTS 
    = ( seed => int( rand() * 32000 ),
        update_interval => 0, # If default used, carps when interactive 
            );

sub _read_commandline{
    my %options;
    GetOptions( \%options,
                "seed=i",
                "log!",
                "tk!",
                "seq=s",
                "update_interval=i",
                "interactive!",
                "max_steps=i",
                    );
    return %options;
}


# method: _read_config_and_commandline
# reads in config/commandline/defaults
#
# Reads the configuration (conf/seqsee.conf), updates what it sees using the commandline arguments, sets defaults, and returns the whole thing in a HASH
#
#    return value:
#       The OptionsRef      

sub _read_config{
    my %options = @_;
    my $RETURN_ref = {};
    read_config 'config/seqsee.conf' => my %config;

    for (qw{seed log tk max_steps 
            interactive update_interval

            UseScheduledThoughtProb ScheduledThoughtVanishProb
            DecayRate
        }) {
        my $val 
            = exists($options{$_})        ? $options{$_} :
              exists($config{seqsee}{$_}) ? $config{seqsee}{$_} :
              exists($DEFAULTS{$_})       ? $DEFAULTS{$_} :
                  confess "Option '$_' not set either on command line, conf file or defauls";
        $RETURN_ref->{$_} = $val;
    }

    $RETURN_ref->{seq} = $options{seq}; # or confess "Sequence not set!";

    # SANITY CHECKING: SEQ
    my $seq = $RETURN_ref->{seq};
    unless ($seq =~ /^[\d\s,]*$/) {
        confess "The option --seq must be a space or comma separated list of integers; I got '$seq' instead";
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
        confess "Seqsee is being used interactively: absolutely must have the update interval: it cannot use the value $RETURN_ref->{update_interval}";
    }

    return $RETURN_ref;
}





1;

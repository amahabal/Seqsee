package Seqsee;
use S;
use version; our $VERSION = version->new( "0.0.3" );

use English qw(-no_match_vars);
use List::Util qw(min max);
use Carp;

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
    $::Steps_Finished++;
    main::do_background_activity();

    ## $Steps_Finished
    my $runnable = SCoderack->get_next_runnable();
    ## $runnable
    return unless $runnable; # prog not yet finished!

    eval {
        if ($runnable->isa("SCodelet")) {
            $::CurrentRunnableString = "SCF::". $runnable->[0];
            $runnable->run();
        } elsif ($runnable->isa("SThought")) {
            $::CurrentRunnableString = ref($runnable);
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
              $opts_ref->{max_steps} - $::Steps_Finished );
    return 1 unless $n > 0; # i.e, okay to stop now!

    my $update_after = $opts_ref->{update_after} || $n;

    my $change_after_last_display = 0;#to prevent repeats at end
    my $program_finished = 0;

    STEP_LOOP: for my $steps_executed (1..$n) {
	$::_BREAK_LOOP = 0;

        ## Interaction_step_n executing step number: $steps_executed
        $program_finished = Seqsee_Step();
        ## Interaction_step_n finished step: $steps_executed 
        $change_after_last_display = 1;
        
        if (not ($steps_executed % $update_after)) {
            main::update_display();
            $change_after_last_display = 0;
        }
        last if $program_finished;
	last if $::_BREAK_LOOP;
    }
    
    main::update_display() if $change_after_last_display;
    return $program_finished;
}




1;

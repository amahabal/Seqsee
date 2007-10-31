package Seqsee;
use strict;
use S;
use version; our $VERSION = version->new("0.0.3");

use English qw(-no_match_vars);
use List::Util qw(min max);
use Carp;
use Smart::Comments;
use Config::Std;
use Getopt::Long;
use Time::HiRes qw( sleep );
use Class::Multimethods;

sub run {
    my (@sequence) = @_;
    SWorkspace->clear();
    SWorkspace->init(@sequence);
    SStream->clear();
    SStream->init();
    SCoderack->clear();
    SCoderack->init();

    _SeqseeMainLoop();

}

# method: do_background_activity
{
    my $TimeLastProgressCheckerLaunched = 0;

    sub do_background_activity {

        if ( $Global::Feature{CodeletTree} ) {
            print {$Global::CodeletTreeLogHandle} "Background\n";
        }

        SCoderack->add_codelet( SCodelet->new( "Reader", 50, {} ) ) if SUtil::toss(0.3);

        my $time_since_last_addn    = $Global::Steps_Finished - $Global::TimeOfNewStructure;
        my $time_since_last_checker = $Global::Steps_Finished - $TimeLastProgressCheckerLaunched;

        if ( $time_since_last_checker > 20
            and SUtil::toss( $time_since_last_addn / 150 ) )
        {
            $TimeLastProgressCheckerLaunched = $Global::Steps_Finished;
            SCodelet->new( "CheckProgress", 100, {} )->schedule();
        }

        SLTM::DecayAll() unless $Global::Steps_Finished % 10;
    }
}

sub already_rejected_by_user {
    my ($aref) = @_;
    my @a      = @$aref;
    my $cnt    = scalar @a;
    for my $i ( 0 .. $cnt - 1 ) {
        my $substr = join( ", ", @a[ 0 .. $i ] );
        ## Chekin for user rejection: $substr
        return 1 if $Global::ExtensionRejectedByUser{$substr};
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

sub Seqsee_Step {
    $Global::Steps_Finished++;
    unless ( $Global::Steps_Finished % 100 ) {
        $Global::AcceptableTrustLevel -= 0.002;
    }
    sleep( $Global::InterstepSleep / 1000 );

    #main::message($Global::InterstepSleep);
    do_background_activity();

    # Global::ClearHilit();

    ## $Global::Steps_Finished
    my $runnable = SCoderack->get_next_runnable();
    return unless $runnable;    # prog not yet finished!

    eval {
        if ( $runnable->isa("SCodelet") )
        {
            if ( $Global::Feature{CodeletTree} ) {
                print {$Global::CodeletTreeLogHandle} "Chose $runnable\n";
            }
            $Global::CurrentRunnableString = "SCF::" . $runnable->[0];
            $runnable->run();
        }
        elsif ( $runnable->isa("SThought") ) {
            if ( $Global::Feature{CodeletTree} ) {
                print {$Global::CodeletTreeLogHandle} "Chose $runnable\n";
            }
            $Global::CurrentRunnableString = ref($runnable);
            ## $runnable
            SStream->add_thought($runnable);
        }
        else {
            SErr::Fatal->throw("Runnable object is $runnable: expected an SThought or a SCodelet");
        }
    };

    if ($Global::Sanity) {
        SanityCheck();
    }

    if ($EVAL_ERROR) {
        my $err = $EVAL_ERROR;
        ## Caught an error: ref($err)
        if ( UNIVERSAL::isa( $err, 'SErr::ProgOver' ) ) {
            return 1;
        }
        if (   UNIVERSAL::isa( $err, 'SErr::NeedMoreData' )
            or UNIVERSAL::isa( $err, 'SErr::ContinueWith' ) )
        {
            if ( $err->forced() ) {
                $err->payload()->force_to_be_next_runnable();
            }
            else {
                $err->payload()->schedule();
            }
            return;
        }

        # main::message("About to call default_error_handler with '$err'");
        # confess "Empty error message" if $err eq q{};
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

sub Interaction_step_n {
    my $opts_ref = shift;
    ## In Interaction_step_n: $opts_ref

    my $n = $opts_ref->{n} or confess "Need n";
    $n = min( $n, $opts_ref->{max_steps} - $Global::Steps_Finished );
    return 1 unless $n > 0;    # i.e, okay to stop now!

    my $update_after = $opts_ref->{update_after} || $n;

    my $change_after_last_display = 0;    #to prevent repeats at end
    my $program_finished          = 0;

STEP_LOOP: for my $steps_executed ( 1 .. $n ) {
        $Global::Break_Loop = 0;

        ## Interaction_step_n executing step number: $steps_executed
        $program_finished = Seqsee_Step();
        ## Interaction_step_n finished step: $steps_executed
        $change_after_last_display = 1;

        if ( not( $steps_executed % $update_after ) ) {
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
my %DEFAULTS = (
    seed            => int( rand() * 32000 ),
    update_interval => 0,                       # If default used, carps when interactive
);

sub _read_commandline {
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
    GetOptions(
        \%options,
        "seed=i",
        "log!",
        "seq=s",
        "update_interval=i",
        "interactive!",
        "max_steps=i", "n=i",    # same option!
        'f=s',
        'gui_config=s', 'gui=s',    # same option!
        'tabbed!',
        'sanity!',
        'view=i',
    );
    $options{max_steps}  ||= $options{n}   if exists $options{n};
    $options{gui_config} ||= $options{gui} if exists $options{gui};
    $options{gui_config} = 'GUI_tabbed' if $options{tabbed};

    # XXX(Board-it-up): [2007/03/05] should be elsewhere!
    $Global::Sanity = 1 if $options{sanity};

    return %options;
}

# method: _read_config_and_commandline
# reads in config/commandline/defaults
#
# Reads the configuration (conf/seqsee.conf), updates what it sees using the commandline arguments, sets defaults, and returns the whole thing in a HASH
#
#    return value:
#       The OptionsRef

sub _read_config {
    my %options    = @_;
    my $RETURN_ref = {};
    read_config 'config/seqsee.conf' => my %config;

    for (
        qw{seed log max_steps
        interactive update_interval

        UseScheduledThoughtProb ScheduledThoughtVanishProb
        DecayRate

        view

        gui_config
        }
        )
    {
        my $val =
              exists( $options{$_} )        ? $options{$_}
            : exists( $config{seqsee}{$_} ) ? $config{seqsee}{$_}
            : exists( $DEFAULTS{$_} )       ? $DEFAULTS{$_}
            :   confess "Option '$_' not set either on command line, conf file or defauls";
        $RETURN_ref->{$_} = $val;
    }

    $RETURN_ref->{seq} = $options{seq};    # or confess "Sequence not set!";

    # SANITY CHECKING: SEQ
    my $seq = $RETURN_ref->{seq};
    unless ( $seq =~ /^[\d\s,]*$/ ) {
        confess
            "The option --seq must be a space or comma separated list of integers; I got '$seq' instead";
    }
    for ($seq) { s/^\s*//; s/\s*$//; }
    my @seq = split( /[\s,]+/, $seq );
    $RETURN_ref->{seq} = [@seq];

    # SANITY CHECKING: interactive
    if ( $RETURN_ref->{tk} and not( $RETURN_ref->{interactive} ) ) {
        print "Using Tk forces interactivity! Reading your mind...\n";
        $RETURN_ref->{interactive} = 1;
    }

    # SANITY CHECKING: update_interval
    if ( $RETURN_ref->{interactive}
        and not( $RETURN_ref->{update_interval} ) )
    {
        confess
            "Seqsee is being used interactively: absolutely must have the update interval: it cannot use the value $RETURN_ref->{update_interval}";
    }

    print "View: $RETURN_ref->{view}!\n";

    return $RETURN_ref;
}

multimethod SanityFail => ('$') => sub {
    my ($m) = @_;
    my $msg
        = "Entered inconsistent state after a $Global::CurrentRunnableString.($Global::Steps_Finished)\n$m";
    main::message($msg);
    confess "Sanity failed... exiting!";
};

multimethod SanityCheck => () => sub {
    for my $gp ( SWorkspace::GetGroups() ) {
        SanityCheck($gp);
    }
    for my $rel ( values %SWorkspace::relations ) {
        SanityCheck($rel);
    }
};

multimethod SanityCheck => qw(SElement) => sub {
    my ($el) = @_;

};

multimethod SanityCheck => qw(SAnchored) => sub {
    my ($gp) = @_;
    if ( my $underlying_ruleapp = $gp->get_underlying_reln() ) {
        SanityCheck( $gp, $underlying_ruleapp );
    }
    my ( $l, $r ) = $gp->get_edges();
    0 <= $l                        or SanityFail("Edge problem: left $l");
    $l <= $r                       or SanityFail("Edge problem: $l $r");
    $r < $SWorkspace::ElementCount or SanityFail("Edge problem: right $r");

    my @parts = @$gp;

    SWorkspace->are_there_holes_here(@parts) and SanityFail("Holes in group!");

    for my $part (@parts) {
        $part->isa('SAnchored') or SanityFail("Unanchored part!");
        $part->get_is_a_metonym() and SanityFail("Group has metonym as part");
    }
};

multimethod SanityCheck => qw(SAnchored SRuleApp) => sub {
    SanityCheck( @_, '' );
};

multimethod SanityCheck => qw(SAnchored SRuleApp $) => sub {
    my ( $gp, $ra, $m ) = @_;
    $m = $m ? "($m) " : "";
    my @gp_parts = @$gp;
    my @ra_items = @{ $ra->get_items() };
    my $count    = scalar(@gp_parts);
    unless ( scalar(@ra_items) == $count ) {
        my $msg = "Group: "
            . $gp->as_text()
            . " has $count elements: @gp_parts, whereas ruleapp only has @ra_items";
        SanityFail("$m Gp/Ruleapp out of sync! $msg");
    }
    for my $i ( 0 .. $count - 1 ) {
        my $gp_part = $gp_parts[$i];
        my $ra_part = $ra_items[$i];
        if ( $gp_part->get_metonym_activeness() ) {

# $gp_part->GetEffectiveObject() eq $ra_part or SanityFail("Metonym'd object had ruleapp with unmetonymd part or different part " . join(";", "Group", $gp, $gp->as_text(), "Part: ", $gp_part, $gp_part->as_text(), $gp_part->GetEffectiveObject(), $ra_part, $ra_part->as_text()));
        }
        else {
            $gp_part eq $ra_part or SanityFail("$m Gp/Ruleapp item out of sync!");
        }
    }
};

multimethod SanityCheck => qw(SReln) => sub {
    my ($rel) = @_;

};

1;

#####################################################
#
#    Package: SStream
#
#####################################################
#   Manages the stream of thought.
#    
#####################################################

package SStream;
use strict;

my $logger;
{
    my ($is_debug, $is_info);
    BEGIN{ $logger   = Log::Log4perl->get_logger("SStream"); 
           $is_debug = $logger->is_debug();
           $is_info  = $logger->is_info();
         }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info;  }
}

# variable: $DiscountFactor
#    controls how fast efect fades with age

my $DiscountFactor            = 0.8;

# variable: $MaxOlderThoughts
#    Maximum number of older thoughts
my $MaxOlderThoughts          = 10;

# variable: $OlderThoughtCount
#    Actual number of Older thoughts
my $OlderThoughtCount         = 0;

# variable: @OlderThoughts
#    Older thoughts, the most recent coming first. Excludes current thought.
my @OlderThoughts             = (); # for order

# variable: %ThoughtsSet
#    Another view of thoughts, but including Current Thought
my %ThoughtsSet               = (); # another view, includes CurrentThought

# variable: %ComponentStrength
#    keeps track of the strength of fringes
my %ComponentStrength         = ();


# variable: $CurrentThought
#    The current thought
my $CurrentThought;



# method: clear
# Clears stream entirely
#
sub clear{
    $OlderThoughtCount   = 0;
    @OlderThoughts       = ();
    $CurrentThought      = undef;
    %ComponentStrength   = ();
}



# method: add_thought
# Adds a thought to the stream, and "thinks it"
#
#    This is a crucial function, so I must document it carefully.
#     
#    Here are the steps of what happens:
#    * The fringe and extended fringe is calculated, by calls to get_fringe() and get_extended_fringe()
#    * These are compared with older thoughts (via the fringes remembered in %ComponentStrength. If there is a hit, then the hit is remembered in the local variable $_hit_with.
#    * The action set of the thought is calculated by a call to get_actions(). This is appended to if there was a hit.
#    * All actions apart from those that are about "future actions" (like launching codelets) are executed. These may add yet more "future actions"
#    * of these future actions, 0 or 1 can be chosen as a thought to schedule, and such scheduling occurs via a call to SCoderack->schedule_thought($thought). Others are launched as codelets via SCoderack->launch_codelets(@...). This interface may change...
#
#    usage:
#     SStream->add_thought( $thought )
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:
#        SErr::ProgOver
#
# THIS IS NOT YET IMPLEMENTED!!

sub add_thought{
    @_ == 2 or die "new thought takes two arguments";
    my ( $package, $thought ) = @_;

    if (LOGGING_DEBUG()) {
        $logger->debug( "SSTREAM: new thought $thought" );
    }
    
    return if $thought eq $CurrentThought;

    if (exists $ThoughtsSet{$thought}) { #okay, so this is an older thought
        unshift( @OlderThoughts, $CurrentThought ) if $CurrentThought;
        @OlderThoughts = grep { $_ ne $thought } @OlderThoughts;
        $CurrentThought = $thought;
        _recalculate_Compstrength();
        $OlderThoughtCount = scalar(@OlderThoughts);
    }

    else {
        SStream->antiquate_current_thought() if $CurrentThought;
        $CurrentThought = $thought;
        $ThoughtsSet{$CurrentThought} = 1;
        _maybe_expell_thoughts();
    }

}



# method: _maybe_expell_thoughts
# Expells thoughts if $MaxOlderThoughts exceeded
#

sub _maybe_expell_thoughts{
    return unless $OlderThoughtCount > $MaxOlderThoughts;
    for (1 .. $OlderThoughtCount - $MaxOlderThoughts) {
        delete $ThoughtsSet{ pop @OlderThoughts };
    }
    $OlderThoughtCount = $MaxOlderThoughts;
    _recalculate_Compstrength();
}


#method: _recalculate_Compstrength
# Recalculates the strength of components from scratch
sub _recalculate_Compstrength{
    %ComponentStrength = ();
    my $multiplicand = 1;
    for my $t (@OlderThoughts) {
        $multiplicand *= $DiscountFactor;
        foreach my $component ( $t->get_fringe() ) {
            $ComponentStrength{ $component } += $multiplicand;
        }
    }
}



# method: init
# Does nothing.
#
#    Here for symmetry with similarly named methods in Coderack etc

sub init{
    my $Optsref = shift;
}



# method: antiquate_current_thought
# Makes the current thought the first old thought
#

sub antiquate_current_thought{
   my $package = shift;
   unshift(@OlderThoughts, $CurrentThought);
   $CurrentThought = undef;
   $OlderThoughtCount++;
   _recalculate_Compstrength();
}

1;

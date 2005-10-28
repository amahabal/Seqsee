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
use Perl6::Form;

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

# variable: %ComponentOwnership_of
#    Who owns a particular component
#
# Key are components. values are hash refs, whose keys are thoughts, values intensities
my %ComponentOwnership_of = ();

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
    %ComponentOwnership_of = ();
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
        $ThoughtsSet{$CurrentThought} = $CurrentThought;
        _maybe_expell_thoughts();
    }
    _think_the_current_thought();
    
}



# method: _think_the_current_thought
# 
#
sub _think_the_current_thought{
    my $thought = $CurrentThought;
    return unless $thought;

    my $fringe = $thought->get_fringe();
    $thought->set_stored_fringe( $fringe );
    my $extended_fringe = $thought->get_extended_fringe();

    my $hit_with = _is_there_a_hit( $fringe, $extended_fringe );

    my @action_set = $thought->get_actions();

    if ($hit_with) {
        my $new_thought = SThought::AreRelated->new( {a => $hit_with,
                                                      b => $thought});
        push @action_set, $new_thought;
    }

    my (@_thoughts, @_codelets, @_actions);
    for my $x (@action_set) {
        my $x_type = ref $x;
        if ($x_type eq "SCodelet") {
            push @_codelets, $x;
        } elsif ($x_type eq "SAction") {
            push @_actions, $x;
        } else {
            confess "Huh? " unless $x->isa("SThought");
            push @_thoughts, $x;
        }
    }

    # Execute the actions
    for (@_actions) {
        $_->conditionally_run();
    }
    
    # Add codelets to coderack
    for (@_codelets) {
        SCoderack->add_codelet( $_ );
    }

    # Choose a thought and schedule it.
    if (@_thoughts) {
        my $idx = int(rand() * scalar(@_thoughts));
        SCoderack->schedule_thought( $_thoughts[$idx] );
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
    %ComponentOwnership_of = ();
    for my $t (@OlderThoughts) {
        my $fringe = $t->get_stored_fringe();
        for my $comp_act (@$fringe) {
            my ($comp, $act) = @$comp_act;
            $ComponentOwnership_of{$comp}{$t} = $act;
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



# method: display_as_text
# prints a string of the stream
#
sub display_as_text{
    my ( $package ) = @_;
    my $thoughts = form
        "*******************************************",
        "Current Thought:                           ",
        "{[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        (defined $CurrentThought) ? $CurrentThought->as_text() : "none",
        "*******************************************",
        "{>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<}",
        ["OLDER THOUGHTS"],
        "{[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
         [map { $_->as_text } @OlderThoughts];
    print $thoughts;
}


# method: _is_there_a_hit
# Is there another thought with a common fringe?
#
# Given the fringe and the extended fringe (each being an array ref, each of whose elements are 2 element array refs, the first being a component and the second the strength, it checks if there is a hit; If there is, the thought with which the hit occured is returned. Perhaps only thoughts of the same core type as the current are returned.
sub _is_there_a_hit{
    my ( $fringe_ref, $extended_ref ) = @_;
    my %components_hit; # keys values same
    my %hit_intensity;  # keys are components, values numbers

    for my $in_fringe (@$fringe_ref, @$extended_ref) {
        my ($comp, $intensity ) = @$in_fringe;
        next unless exists $ComponentOwnership_of{$comp};
        $components_hit{$comp} = $comp;
        $hit_intensity{$comp} = $intensity;
    }

    # Now get a list of which thoughts are hit.
    my %thought_hit_intensity;  # keys are thoughts, values intensity

    for my $comp (values %components_hit) {
        next unless exists $ComponentOwnership_of{$comp};
        my $owner_ref = $ComponentOwnership_of{$comp};
        my $intensity = $hit_intensity{$comp};
        for my $tht (keys %$owner_ref) {
            $thought_hit_intensity{$tht} += 
                $owner_ref->{$tht} * $intensity;
        }
    }
    
    # Dampen their effect...
    my $dampen_by = 1;
    for my $i (0..$OlderThoughtCount-1) {
        $dampen_by *= $DiscountFactor;
        my $thought = $OlderThoughts[$i];
        next unless exists $thought_hit_intensity{$thought};
        $thought_hit_intensity{$thought} *= $dampen_by;
    }

    # Okay, so now I have done the hard work, but I do not have a good choosing mechanism yet!
    # Will just choose maximum intensity
    my @sorted_thoughts = 
        sort { $thought_hit_intensity{$b} <=> $thought_hit_intensity{$a} }
            keys %thought_hit_intensity;
    return unless @sorted_thoughts;
    return $ThoughtsSet{ $sorted_thoughts[0] };
}


1;

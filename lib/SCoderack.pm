#####################################################
#
#    Package: SCoderack
#
#####################################################
#   Manages the coderack.
#    
#   TODO:
#    * I am thinking of limiting $MAX_CODELETS to about 25; In that scenario, the entire bucket system would be a needless overhead.
#    * When a codelet is created, it would have weakened any references it makes. There should be a function called purge_defunct() that would get rid of codelets whose some argument is undef. Also, a call to get codelet should check for this. 
#   * need methods to schedule thoughts, to add several codelets and a method get_runnable()
#####################################################

package SCoderack;
use strict;
use Carp;
use Config::Std;
use Smart::Comments;


# variable: $MAX_CODELETS
#    Maximum number of codelets allowed
my $MAX_CODELETS = 25;

# variable: $codelet_count
#    How many codelets are in there currently?
my $codelet_count = 0;

# variable: @codelets
#    The actual codelets
my @codelets;

# variable: $urgencies_sum
#    Sum of all urgencies
my $urgencies_sum = 0;

# variable: $scheduled_thought
#    The though if any scheduled, undef o/w
my $scheduled_thought;

clear();



# method: clear
# makes it all empty
#
sub clear{
    $codelet_count = 0;
    $urgencies_sum = 0;
    @codelets = ();
    $scheduled_thought = undef;
}



# method: init
# Initializes codelets from a config file.
#
# Ignores the passed OPTIONS_ref, but reads initialization info from a config file
#
sub init{
    my $package = shift; # $package
    my $OPTIONS_ref = shift;
    # I am not going to use any of the options here, at least for now.
    # Codelet configuarion for startup should be read in from another configuration file config/start_codelets.conf
    # die "This is where I left yesterday";

    read_config 'config/start_codelets.conf' => my %launch_config;
    for my $family (keys %launch_config) {
        next unless $family;
        ## Family: $family
        my $urgencies = $launch_config{$family}{urgency};
        ## $urgencies
        my @urgencies = (ref $urgencies) ? (@$urgencies) : ($urgencies);
        ## @urgencies
        for (@urgencies) {
            # launch!
            $package->add_codelet(
                new SCodelet( $family, $_, {})
                    );
        }
    }
}



# method: add_codelet
# Adds the given codelet to the coderack
#

sub add_codelet{
    my ( $package, $codelet ) = @_;
    confess "A non codelet is being added" unless $codelet->isa("SCodelet");
    $codelet_count++;
    if ($codelet_count > $MAX_CODELETS) {
        confess "Haven't implemented expunging codelets yet";
    }
    push(@codelets, $codelet);
    $urgencies_sum += $codelet->[1];
}



# method: _choose_codelet
# Chooses a codelet, and returns the index of a codelet.
#

sub _choose_codelet{
    return undef unless $codelet_count;
    confess "In Coderack: urgencies sum 0, but codelet count non-zero"
        unless $urgencies_sum;    

    my $random_number = 1 + int( rand($urgencies_sum) );
    my $index         = 0;
    while ( $random_number > $codelets[$index]->[1] ) {
        $random_number -= $codelets[$index]->[1];
        $index++;
    }
    return $index


}

############## ACCESSORS, mostly for testing

sub get_urgencies_sum { return $urgencies_sum }
sub get_codelet_count { return $codelet_count }



# method: get_next_runnable
# returns a codelet or a thought.
#
#    If no thought is scheduled, just uses _choose_codelet to find the index of a codelet to return.
#     
#    If there IS a scheduled though, though, with a 70% probability it is chosen, else a codelet is chosen. This is a first cut interface, of course, will update as I get wiser.
#     
#    The scheduled thought, if not chosen, is NOT overwritten
sub get_next_runnable{
    my ( $package ) = @_;

    if ($scheduled_thought) {
        my $use_scheduled = SUtil::toss(0.7);
        if ($use_scheduled) {
            my $to_return = $scheduled_thought;
            $scheduled_thought = undef;
            return $to_return;
        }
    }
    
    # If I reach here, return some codelet
    unless ($codelet_count) {
        confess "No scheduled though or any codelets. Don't know what to do";
    }
    
    my $idx = _choose_codelet();
    my $to_return = splice(@codelets, $idx);
    $urgencies_sum -= $to_return->[1];
    $codelet_count--;
    return $to_return;
}



1;

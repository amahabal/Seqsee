#####################################################
#
#    Package: SCoderack
#
#####################################################
#   Manages the coderack.
#
#   TODO:
#    * I am thinking of limiting $MAX_CODELETS to about 25; In that scenario, the entire bucket
# system would be a needless overhead.
#    * When a codelet is created, it would have weakened any references it makes. There should
# be a function called purge_defunct() that would get rid of codelets whose some argument is
# undef. Also, a call to get codelet should check for this.
#   * need methods to schedule thoughts, to add several codelets and a method get_runnable()
#####################################################

package SCoderack;
use strict;
use Carp;
use Config::Std;
use Smart::Comments;
use Perl6::Form;

my $logger;
{
    my ( $is_debug, $is_info );

    BEGIN {
        $logger   = Log::Log4perl->get_logger("SCoderack");
        $is_debug = $logger->is_debug();
        $is_info  = $logger->is_info();
    }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info; }
}

my $MAX_CODELETS  = 25;    # Maximum number of codelets allowed.
my $CODELET_COUNT = 0;     #    How many codelets are in there currently?
our @CODELETS;             #    The actual codelets
our $URGENCIES_SUM = 0;            #    Sum of all urgencies
our $SCHEDULED_THOUGHT;            #    The though if any scheduled, undef o/w
our $FORCED_THOUGHT;               #    If set, get next runnable returns this, no matter what
my $UseScheduledThoughtProb;       #    Likelihood that the current scheduled thought is used
my $ScheduledThoughtVanishProb;    #    Prob. that scheduled thought is annhilated if unused
our $LastSelectedRunnable;         # Last selected codelet/thought

our %HistoryOfRunnable;

clear();

# method: clear
# makes it all empty
#
sub clear {
    $CODELET_COUNT     = 0;
    $URGENCIES_SUM     = 0;
    @CODELETS          = ();
    $SCHEDULED_THOUGHT = undef;
    $FORCED_THOUGHT    = undef;
    %HistoryOfRunnable = ();
}

# method: init
# Initializes codelets from a config file.
#
# Ignores the passed OPTIONS_ref, but reads initialization info from a config file
#
sub init {
    my $package     = shift;    # $package
    my $OPTIONS_ref = shift;
    print "Initializing Coderack...\n";

    if ($Global::Feature{CodeletTree}) {
        open my $handle, '>', $Global::CodeletTreeLogfile;
        select($handle);
        $| = 1;
        select(*STDOUT);
        $| = 1;
        $Global::CodeletTreeLogHandle = $handle;
        #print "Handle: $handle\n";
        #print {$Global::CodeletTreeLogHandle} "Handle: $handle\n";
    }

    $UseScheduledThoughtProb    = $OPTIONS_ref->{UseScheduledThoughtProb};
    $ScheduledThoughtVanishProb = $OPTIONS_ref->{ScheduledThoughtVanishProb};

# Codelet configuarion for startup should be read in from another configuration file config/start_codelets.conf
# die "This is where I left yesterday";

    read_config 'config/start_codelets.conf' => my %launch_config;
    for my $family ( keys %launch_config ) {
        next unless $family;
        ## Family: $family
        my $urgencies = $launch_config{$family}{urgency};
        ## $urgencies
        my @urgencies = ( ref $urgencies ) ? (@$urgencies) : ($urgencies);
        ## @urgencies
        for (@urgencies) {

            # launch!
            $package->add_codelet( new SCodelet( $family, $_, {} ) );
        }
    }
}

# method: add_codelet
# Adds the given codelet to the coderack
#

sub add_codelet {
    my ( $package, $codelet ) = @_;
    confess "A non codelet is being added" unless $codelet->isa("SCodelet");
    if ( LOGGING_DEBUG() ) {
        $logger->debug(": codelet added: $codelet->[0]");
    }
    $CODELET_COUNT++;
    push( @CODELETS, $codelet );
    if ($Global::Feature{CodeletTree}) {
        print {$Global::CodeletTreeLogHandle} "\t$codelet\t$codelet->[0]\n";
    }
    $URGENCIES_SUM += $codelet->[1];
    if ( $CODELET_COUNT > $MAX_CODELETS ) {
        expunge_codelet();
    }
}

# method: _choose_codelet
# Chooses a codelet, and returns the index of a codelet.
#

sub _choose_codelet {
    return undef unless $CODELET_COUNT;
    confess "In Coderack: urgencies sum 0, but codelet count non-zero"
        unless $URGENCIES_SUM;

    ## _choose_codelet: $CODELET_COUNT, $URGENCIES_SUM

    my $random_number = 1 + int( rand($URGENCIES_SUM) );
    ## _choose_codelet random_number: $random_number
    ## @CODELETS
    my $index = 0;
    while ( $random_number > $CODELETS[$index]->[1] ) {
        $random_number -= $CODELETS[$index]->[1];
        $index++;
    }
    ## _choose_codelet returning: $index
    return $index;

}

# ACCESSORS, mostly for testing

sub get_urgencies_sum { return $URGENCIES_SUM }
sub get_codelet_count { return $CODELET_COUNT }

# method: get_next_runnable
# returns a codelet or a thought.
#
#    If no thought is scheduled, just uses _choose_codelet to find the index of a codelet to return.
#
#    If there IS a scheduled though, though, with a 70% probability it is chosen, else a codelet is chosen. This is a first cut interface, of course, will update as I get wiser.
#
#    The scheduled thought, if not chosen, is NOT overwritten
sub get_next_runnable {
    my ($package) = @_;
    $Global::LogString = "\n\n=======\nLogged Message:\n===\n";
    ## get_next_runnable, scheduled: $SCHEDULED_THOUGHT

    if ($FORCED_THOUGHT) {
        my $to_return = $FORCED_THOUGHT;
        $FORCED_THOUGHT = undef;
        $HistoryOfRunnable{ref($to_return)}++;
        return $LastSelectedRunnable = $to_return;
    }

    if ($SCHEDULED_THOUGHT) {
        ## SCheduled Thought Present
        ## $CODELET_COUNT
        my $use_scheduled = SUtil::toss($UseScheduledThoughtProb);
        ## $use_scheduled
        if ( $use_scheduled or ( $CODELET_COUNT == 0 ) ) {
            ## get_next_runnable, using scheduled:
            my $to_return = $SCHEDULED_THOUGHT;
            $SCHEDULED_THOUGHT = undef;
            ## $SCHEDULED_THOUGHT
            $HistoryOfRunnable{ref($to_return)}++;
            return $LastSelectedRunnable = $to_return;

        }
        elsif ( SUtil::toss($ScheduledThoughtVanishProb) ) {
            $SCHEDULED_THOUGHT = undef;
        }
    }
    ## get_next_runnable, NOT using scheduled
    # If I reach here, return some codelet
    unless ($CODELET_COUNT) {
        confess "No scheduled though or any codelets. Don't know what to do";
    }

    my $idx = _choose_codelet();
    my $to_return = splice( @CODELETS, $idx, 1 );
    $HistoryOfRunnable{'SCF::' . $to_return->[0]}++;
    $URGENCIES_SUM -= $to_return->[1];
    $CODELET_COUNT--;
    return $LastSelectedRunnable = $to_return;
}

# method: display_as_text
# prints a string of the coderack, for debugging etc
#
sub display_as_text {
    my ($package) = @_;
    print form "=========================================================",
        "Scheduled Thought: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        ( defined $SCHEDULED_THOUGHT ) ? $SCHEDULED_THOUGHT->as_text() : "none",
        "=========================================================", "Codelets: ",
        "      {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        [ map { form "{<<<<<<<<<<} {>>>>>>>} ", $_->[0], $_->[1] } @CODELETS ],
        "=========================================================";
}

# method: force_thought
# Set the forced thought to this
#
sub force_thought {
    my ( $package, $thought ) = @_;
    $FORCED_THOUGHT = $thought;
    if ( LOGGING_DEBUG() ) {
        $logger->debug( ": forced thought: ", $thought->as_text() );
    }
}

# method: schedule_thought
# Set the scheduled thought to this
#
sub schedule_thought {
    my ( $package, $thought ) = @_;
    $SCHEDULED_THOUGHT = $thought;
    if ( LOGGING_DEBUG() ) {
        $logger->debug( ": scheduled thought: ", $thought->as_text() );
    }
}

# method: expunge_codelet
# Gets rid of the minimum urgency codelet.
#
sub expunge_codelet {
    @CODELETS = sort { $b->[1] <=> $a->[1] } @CODELETS;
    my $cl = pop(@CODELETS);
    $CODELET_COUNT--;
    $URGENCIES_SUM -= $cl->[1];
}

1;

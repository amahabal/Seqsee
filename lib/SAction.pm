#####################################################
#
#    Package: SAction
#
#####################################################
# Codelets that run "immediately"
#
#Actions are really like codelets---in fact, they share almost all the code
#---except they never see the coderack. These are actions that get taken
#immediately, with a certain probability.
#
#For any thought, it is possible to call the function get_actions(). This
#returns a bunch of codelets (which get scheduled) and a bunch of actions,
#which may get executed based on their urgencies.
#
#Running an action is just like running a codelet. Every action has a
#codefamily associated with it.
#####################################################

package SAction;
use strict;
use Carp;
use Class::Std;
use Scalar::Util qw(blessed);
use base qw{};

my %family_of : ATTR( :get<family>);       # Family. Without the prefix SCF::.
my %urgency_of : ATTR( :get<urgency> );    # Probability of running: 0 to 100.
my %args_of_of : ATTR;                     # Options.

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $family_of{$id}  = $opts_ref->{family}  or confess "Need family";
    $urgency_of{$id} = $opts_ref->{urgency} or confess "Need urgency";
    $args_of_of{$id} = $opts_ref->{args}    or confess "Need args";
}

# method: conditionally_run
# run with probability equal to urgency.
sub conditionally_run {
    my ($self) = @_;
    my $id = ident $self;

    if ($Global::debugMAX) {
        main::message("About to take action $family_of{$id}: " .
                          SUtil::StringifyForCarp($args_of_of{$id}));
    }

    return unless ( SUtil::toss( $urgency_of{$id} / 100 ) );
    if ($Global::Feature{CodeletTree}) {
        print {$Global::CodeletTreeLogHandle} "\t$self\t$family_of{$id}\t100\n";
        print {$Global::CodeletTreeLogHandle} "acted $self\n";
    }
    no strict;
    my $family = $family_of{$id};
    $SCoderack::HistoryOfRunnable{"SCF::$family"}++;
    $Global::CurrentCodelet = $self;
    $Global::CurrentCodeletFamily = 'Action ' . $family;
    my $code   = *{ "SCF::$family" . "::run" }{CODE}
        or SCodelet::fishy_codefamily($family);
    $code->( $self, $args_of_of{$id} );
}

1;


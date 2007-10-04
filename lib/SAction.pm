#####################################################
#
#    Package: SAction
#
#####################################################
#Codelets that run "immediately"
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

    return unless ( SUtil::toss( $urgency_of{$id} / 100 ) );
    if ($Global::Feature{CodeletTree}) {
        print {$Global::CodeletTreeLogHandle} "acted $self\n";
    }
    no strict;
    my $family = $family_of{$id};
    $SCoderack::HistoryOfRunnable{"SCF::$family"}++;
    my $code   = *{ "SCF::$family" . "::run" }{CODE}
        or SCodelet::fishy_codefamily($family);
    $code->( $self, $args_of_of{$id} );
}

# method: generate_log_msg
# Called from individual code families only if this will get logged, returns a string that can be logged.
#
sub generate_log_msg {
    my ($self) = @_;
    my $id     = ident $self;
    my $family = $family_of{$id};

    my $ret = join( "", "\n=== $Global::Steps_Finished ", "=" x 10, "  ACTION $family\n" );
    while ( my ( $k, $v ) = each %{ $args_of_of{$id} } ) {
        my $val = ( blessed $v) ? $v->as_text() : $v;
        $ret .= "== $k \t--> $val\n";
    }
    return $ret;
}

1;


#####################################################
#
#    Package: SNode
#
#####################################################
#   Things that can have activations
#####################################################

package SNode;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use base qw{};

my %core_of : ATTR( :get<core>);
my %name_of : ATTR( :get<name>);

our %MEMOIZE;
our $DECAY_RATE;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $core_of{$id} = $opts_ref->{core} or confess "no core for snode!!";
    $name_of{$id} = "Node " . $core_of{$id}->as_text();
}

1;


#####################################################
#
#    Package: SBlemish
#
#####################################################
#   Manages individual blemishes
#####################################################

package SBlemish;
use strict;
use Carp;
use Class::Std;

use base qw{SInstance};


# variable: %blemished_of
#    The blemished version of the object
my %blemished_of : ATTR ( :get<blemished> );


# variable: %unblemished_of
#    The unblemished version
my %unblemished_of : ATTR ( :get<unblemished> );



# method: BUILD
# Builds
#
#    TODO:
#    * maybe weaken refs

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $blemished_of{$id}   = $opts_ref->{blemished}   or die "need blemished";
    $unblemished_of{$id} = $opts_ref->{unblemished} or die "need unblemished";
}

1;

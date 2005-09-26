#####################################################
#
#    Package: SRel
#
#####################################################
#   Manages relations between objects
#
#   A relation just keeps track of the two objects, and everything else is handled through the category system.
#####################################################

package SRel;
use strict;
use Carp;
use Class::Std;

use base qw{SInstance};


# variable: %first_of
#    Ref to the first of the two objects. 
#     
#    Does not necessarily mean the left object.
my %first_of : ATTR( :get<first> );


# variable: %second_of
#    Ref to the second
my %second_of : ATTR ( :get<second> );



# method: get_both
# Returns both the objects

sub get_both{
    my $self = shift;
    my $ident = ident $self;
    return ( $first_of{$ident}, $second_of{$ident} );
}



# method: BUILD
# builds
#
#    Would surely need to be modified. Changes needed:
#    * weaken refs
#    * Memoize in some intelligent way
#    * make these remembered by objects.

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $first_of{$id}   = $opts_ref->{first}  or die "Need first";
    $second_of{$id}  = $opts_ref->{second} or die "Need second";
}

1;

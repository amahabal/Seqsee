# New base class for categories of objects.

package SCat::OfObj;
use strict;
use Carp;
use Class::Std;
use base qw{SInstance SCat};
use English qw(-no_match_vars);
use Smart::Comments;
use Memoize;

use Class::Multimethods;
multimethod is_instance => qw(SCat::OfObj SObject) => sub {
    my ( $cat, $object ) = @_;
    my $bindings =  $cat->Instancer( $object ) or return;
    $object->add_category( $cat, $bindings );

    return $bindings;
};

sub is_metonyable{
    my ( $self ) = @_;
    return $S::IsMetonyable{$self};
}

# method: find_metonym
# finds a metonymy
#
#    Arguments:
#    $cat - The category the metonymy will be based on
#    $object - the object whose metonymy is being sought
#    $name - the name of the metonymy, as the cat may support several
#     
#    Please note that the object must already have been seen as belonging to the category.
#     
#    Example:
#    >$cat->find_metonym( $object, $name )

sub find_metonym{
    my ( $cat, $object, $name ) = @_;

    my $finder = $cat->get_meto_finder( $name )
        or croak "No '$name' meto_finder installed for category $cat";
    my $bindings = $object->GetBindingForCategory( $cat ) 
        or croak "Object must belong to category";

    my $obj =  $finder->( $object, $cat, $name, $bindings );
    ## next line kludgy
    if (UNIVERSAL::isa($object, "SAnchored")) {
        $obj->get_starred->set_edges( $object->get_edges );
    }
    
    return $obj;
}

sub get_squintability_checker{
    my ( $self ) = @_;
    # XXX(Board-it-up): [2006/12/29] Currently just returns No. Should be different for some categories.
    return;
}

sub get_meto_types {
    my ( $self ) = @_;
    return;
}
memoize('get_meto_types');


1;

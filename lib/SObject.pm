#####################################################
#
#    Package: SObject
#
#####################################################
#   Workspace objects
#    
#   Redoind SBuiltObj and SInt. This unifies both. Both these packages had accumulated a lot of cruft, including several constructors, a large number of structure related methods and so forth
#####################################################

package SObject;
use strict;
use Carp;
use Class::Std
use base qw{ SInstance};


# variable: %items_of
#    The items of this object. 
#     
#    These can be integers, or other SObjects.
#     
#    It is guarenteed that if there is a single object, it will be an SInt: So, no vacuosly deep groups like [[[3]]]
my %items_of : ATTR;


# variable: %group_p_of
#    Is this object a group? 
#     
#    It certainly is if there are several items, but can also be a group with a single item.
my %group_p_of : ATTR;

#
# Section: Construction

# method: BUILD
#  Builds.
#
#    opts_ref only takes items and group_p

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    die "Need group_p" unless exists $opts_ref->{group_p};

    $items_of{$id}   = $opts_ref->{items} or die "Need items";
    $group_p_of{$id} = $opts_ref->{group_p};
}



# method: create
# shortest way to create an object
#
#    Takes a list of arguments, each of which can be:
#    * An integer,
#    * Another SObject
#    * An array ref, each of whose elements is like those described here.
#     
#    If there is a single argument that is an array ref, the "square brackets are removed".
#
#    usage:
#     SObject->create(...)
#
#    parameter list:
#
#    return value:
#      An SObject
#
#    possible exceptions:

sub create{
    my $package = shift;
    
    my @arguments = @_;

    if (! @arguments) {
        die "Don't know how to create objects with no elements!";
    }

    # Convert Sobjects to array refs...
    @arguments = map { 
        UNIVERSAL::isa($_, "SObject") ? $_->get_structure() : $_
    } @arguments;

    if (@arguments == 1 and ref($arguments[0])) {
        # Single argument which is an array ref
        return $package->create(@{ $arguments[0] });
    }

    # Finally, convert all arrays to objects, too!
    @arguments = map { ref($_) ? $package->create($_) : $_ } @arguments;

    my $group_p = (@arguments == 1) ? 0 : 1;

    return $package->new( { items   => \@arguments,
                            group_p => $group_p,
                        });

}

1;


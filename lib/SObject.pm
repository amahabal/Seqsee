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
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use base qw{SInstance};


# variable: %items_of
#    The items of this object. 
#     
#    These can be integers, or other SObjects.
#     
#    It is guarenteed that if there is a single object, it will be an SInt: So, no vacuosly deep groups like [[[3]]]
my %items_of : ATTR( :get<parts_ref> );


# variable: %group_p_of
#    Is this object a group? 
#     
#    It certainly is if there are several items, but can also be a group with a single item.
my %group_p_of : ATTR( :get<group_p>);


# variable: %metonym_of
#    The metonym associated with this object
my %metonym_of :ATTR( :get<metonym> );

#
# subsection: Construction

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
    @arguments = map { _create_or_int($_) } @arguments;

    my $group_p = (@arguments == 1) ? 0 : 1;

    return $package->new( { items   => \@arguments,
                            group_p => $group_p,
                        });

}



# method: _create_or_int
# creates the object, or just returns int
#
# clearly just a helper

sub _create_or_int{
    my $object = shift;

    if (ref $object) {
        # An array ref..
        my @objects = @$object;
        if (@objects == 1) {
            return _create_or_int( $objects[0] );
        } else {
            return SObject->create(@objects);
        }
    } else {
        return $object;
    }
}


# method: create_from_string
# TODO
#
#    Creates an object given a string.

sub create_from_string{
    my ( $package, $string ) = @_;
    # XXX: ...
}



# method: clone_with_cats
# Makes a clone, maintaining category information
#
#    I don't quite know why this would be needed. Cloning without categories is easy: C< SObject->create( $self->get_structure() ) > 

sub clone_with_cats{
    my $self = shift;
    my $id = ident $self;

    my $items_ref = $items_of{$id};
    my @items = map { ref($_) ? $_->clone_with_cats() : $_ } @{$items_ref};
    my $group_p = $group_p_of{$id};

    my $object = SObject->new( {items => \@items,
                                group_p => $group_p,
                            });
    $object->inherit_categories_from( $self );
    
    return $object;
}

#
# SubSection: Structure related methods
#

# method: get_structure
# returns the structure, a deep array of integers
#
#    Returns an array ref of integers and other array refs of integers, unblessed.

sub get_structure{
    my ( $self ) = shift;
    my $id = ident $self;

    my $items_ref = $items_of{$id};
    my @new_items = map { ref($_) ? $_->get_structure() : $_ } @$items_ref;
    return \@new_items;

}



# method: get_flattened
# get a flattened version
#
#    Returns an arrayref of integers.

sub get_flattened{
    my ($self) = @_;
    my $id = ident $self;
    
    my $items_ref = $items_of{$id};
    my @items = map { ref($_) ? @{ $_->get_flattened() } : ($_) } @$items_ref;

    return \@items;
}



# method: get_parts_count
# how many parts does the object have?
#

sub get_parts_count{
    my $id = ident shift;
    return scalar( @{ $items_of{$id} });
}



# method: get_parts_ref
# returns a ref of the parts. 
#
#    Don't mess with the parts, though!
#   
#    Defined with items above



# method: can_be_seen_as
# Returns if object can be seen as the given structure
#
# WARNING: DOCUMENTATION OUT OF SYNC WITH CODE
#
#    Blow by blow account:
#    * First checks if there is a direct metonymy connecting the two.
#    * If not, checks if the two have the same structure.
#    * Else, checks that they have the same length, and the corresponding parts can be seen as each other.
#
#    usage:
#     $object->can_be_seen_as([3,4,5])
#
#    parameter list:
#        $self - the object
#        $seen_as - seen as
#
#    return value:
#      A hash ref of slippages that happened.
#
#    possible exceptions:

sub can_be_seen_as{
    my ( $self, $seen_as ) = @_;
    ## can_be_seen_as: $self, $seen_as
    my $id = ident $self;
    $seen_as = $seen_as->get_structure();
    ## seen as now: $seen_as

    if (SUtil::compare_deep($seen_as, $self->get_structure())) {
        return {};
    }
    
    if ($metonym_of{$id}) {
        if (SUtil::compare_deep($seen_as, $metonym_of{$id}->get_starred())) {
            return {};
        }
    }

    my $seen_as_parts_count = scalar(@$seen_as);
    return unless $seen_as_parts_count == $self->get_parts_count;

    my %return = ();
    my $parts_ref = $self->get_parts_ref;
    for my $i (0 .. $seen_as_parts_count - 1) {
        my $obj_part = $parts_ref->[$i];
        my $seen_as_part = $seen_as->[$i];
        my $meto = _can_be_seen_as_no_rec( $obj_part, $seen_as_part );
        
        unless (defined $meto) { # cannot be so seen!
            return;
        }

        unless ($meto) { # can be seen without slippage
            next;
        }

        $return{$i} = $meto;

    }
    return \%return;
}



# multi: _can_be_seen_as_no_rec ( SObject, # )
# Can the object be seen as the int?
#
multimethod _can_be_seen_as_no_rec => ('SObject', '#') => sub {
    my ( $object, $int ) = @_;
    my $id = ident $object;

    if (SUtil::compare_deep($object->get_structure(), [$int])) {
        return 0;
    } elsif ($metonym_of{$id} and $metonym_of{$id}->get_starred() == $int) {
        return $metonym_of{$id};
    } else {
        return;
    }
};

multimethod _can_be_seen_as_no_rec => ('#', '#') => sub {
    my ( $a, $b ) = @_;
    if ($a == $b) { return 0;
                } else {
                    return;
                }
};



#
# subsection: Positions and ranges
#
# Methods dealing with positions
#
#



# method: get_subobj_given_range
#  Get the subobject
#
#    Range is a flat array of indices in the array. This method returns an array ref of items in that range.
#
# Change (Oct 14 2005):If range has a single number, no [] is wrapped around it.
#
#  Exceptions:
#      SErr::Pos::OutOfRange

sub get_subobj_given_range {
    my ( $self, $range ) = @_;
    my $items_ref = $items_of{ ident $self };

    my @ret;

    for (@$range) {
        my $what = $items_ref->[$_];
        defined $what or SErr::Pos::OutOfRange->throw();
        push @ret, $what;
    }

    if (@$range == 1) {
        return $ret[0];
    }

    return \@ret;
}



# method: get_at_position
# Returns subobject at given position
#

sub get_at_position { #( $self: $position )
    my ( $self, $position ) = @_;
    UNIVERSAL::isa( $position, "SPos" ) or croak "Need SPos";

    my $range = $position->find_range($self);
    return $self->get_subobj_given_range($range);
}

#
# subsection: Testing utilities(methods)



# method: structure_ok
# checks if structure matches the argument, and cals ok or nok
#

sub structure_ok{
    my ( $self, $structure ) = @_;
    my $struct = $self->get_structure;
    ## $struct, $structure
    if (SUtil::compare_deep($struct, $structure)) {
        Test::More::ok(1,"structure ok");
    } else {
        Test::More::ok(0, "structure ok");
    }
}


1;


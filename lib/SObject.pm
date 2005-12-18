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
use English qw(-no_match_vars);
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
my %metonym_of :ATTR( :get<metonym> :set<metonym>);


# variable: %relns_from_of
#    outgoing relations. A hashref indexed by the other object.
my %relns_from_of :ATTR( :get<relns_from> :set<relns_from>);

# variable: %relns_to_of
#    incoming
my %relns_to_of :ATTR( :get<relns_to> :set<relns_to>);


# variable: %underlying_reln_of
#    is the group based on some relation? undef if not, the relation otherwise
my %underlying_reln_of :ATTR( :get<underlying_reln> :set<underlying_reln>);

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
    $relns_from_of{$id} = {};
    $relns_to_of{$id} = {};
    $underlying_reln_of{$id} = undef;
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
        $package->new( { group_p => 1,
                         items   => [],
                });
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



# method: quik_create
# Creates the object, adding metonyms as needed
#
#    For any subobject, if all of its elements are the same, adds the category-annotation for sameness group, and adds a metonymy

sub quik_create{
    my ( $package, $array_ref, @potential_cats ) = @_;
    my $object = $package->create(@$array_ref);
    my $id = ident $object;
    
    LOOP: for my $subobject (@{ $items_of{$id} }) {
        next unless ref($subobject);
        
        my $subid = ident $subobject;
        # now check if all elements in it are the same.
        my $parts_ref = $items_of{$subid};
        my $count = scalar(@$parts_ref);
        my $first_part = $parts_ref->[0];

        for my $i (1..$count-1) {
            unless ($first_part eq $parts_ref->[$i]) {
                next LOOP;
            }
        }
        
        # So a sameness group has been seen.
        $subobject->annotate_with_cat($S::SAMENESS);
        $subobject->annotate_with_metonym($S::SAMENESS, "each");
    }

    for (@potential_cats) {
        $object->maybe_annotate_with_cat($_);
    }

    return $object;
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
# SubSection: Annotation


# method: annotate_with_cat
# Annotattes object as belonging to category
#
#    The object must belong to the category: must pass is_instance, otherwise an exception is raised.
#
#    usage:
#     $object->annotate_with_cat($cat)
#
#    parameter list:
#        $self - the object
#        $cat -  the category
#
#    return value:
#      none
#
#    possible exceptions:
#        SErr::NotOfCat

sub annotate_with_cat{
    my ( $self, $cat ) = @_;
    my $bindings = $cat->is_instance( $self );

    SErr::NotOfCat->throw() unless $bindings;

    $self->add_category($cat, $bindings);
}



# method: maybe_annotate_with_cat
# Similar to annotate_with_cat, except does not throw exception if the object cannot belong to the cat.
#
#    In fact, it does a add_non_cat in that situation.

sub maybe_annotate_with_cat{
    my ( $self, $cat ) = @_;
    eval { $self->annotate_with_cat($cat) };

    if ($EVAL_ERROR) {
        $self->add_non_category($cat);
    }
}



# method: annotate_with_metonym
# Adds a metonym from the given category to the object
#
#    Dies if metonym application not possible.
#
#    usage:
#     $object->annotate_with_metonym( $cat, $name )
#
#    parameter list:
#        $self - The object
#        $cat - category
#        $name - name of metonymy
#
#    return value:
#      none
#
#    possible exceptions:
#        SErr::MetonymNotAppicable

sub annotate_with_metonym{
    my ( $self, $cat, $name ) = @_;
    my $is_of_cat_ref = $self->is_of_category_p($cat);

    unless ($is_of_cat_ref->[0]) {
        $self->annotate_with_cat($cat);
    }

    my $meto = $cat->find_metonym( $self, $name );
    SErr::MetonymNotAppicable->throw() unless $meto;

    $self->set_metonym( $meto );
}



# method: maybe_annotate_with_metonym
#  same as annotate_with_metonym, except does not die
#
# XXX: too bad this will trap *all* errors. Should change that.

sub maybe_annotate_with_metonym{
    my ( $self, $cat, $name ) = @_;
    eval { $self->annotate_with_metonym($cat, $name) };
    
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



# method: arrayify
# Get the numbered part, 0  indexed
#
#    automatically used when object is treated as an array ref

sub arrayify :ARRAYIFY{
    my $self = shift;
    return $items_of{ident $self};
}

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
    ## parts count okay
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



# method: can_be_seen_as_int
# What integer can this object be seen as?
#
#    returns undef if none.
#     
#    Just uses the metonym: if it's starred is an int, return that, else retrun undef.
#
sub can_be_seen_as_int{
    my ( $self ) = @_;
    my $id = ident $self;

    my $meto = $metonym_of{$id};
    return unless $meto;

    my $starred = $meto->get_starred;
    if (ref $starred) {
        return;
    }

    return $starred;
}




# multi: _can_be_seen_as_no_rec ( SObject, # )
# Can the object be seen as the int?
#
multimethod _can_be_seen_as_no_rec => ('SObject', '#') => sub {
    my ( $object, $int ) = @_;
    my $id = ident $object;

    ## _can_be_seen_as_no_rec: $object, $int
    ## $metonym_of{$id}
    if (SUtil::compare_deep($object->get_structure(), [$int])) {
        return 0;
    } elsif ($metonym_of{$id} and $metonym_of{$id}->get_starred() == $int) {
        return $metonym_of{$id};
    } else {
        return;
    }
};



# multi: _can_be_seen_as_no_rec ( #, # )
# The two should be equal
#


multimethod _can_be_seen_as_no_rec => ('#', '#') => sub {
    my ( $a, $b ) = @_;
    if ($a == $b) { return 0;
                } else {
                    return;
                }
};



# method: tell_forward_story
# Given a category, reinterprets bindings for that category so that positions are expressed in a forward direction.
#

sub tell_forward_story{
    my ( $self, $cat ) = @_;
    my $bindings = $self->get_binding($cat);
    confess "Object $self does not belong to category ". $cat->get_name()
        unless $bindings;
    $bindings->tell_forward_story($self);
}

# method: tell_backward_story
# Given a category, reinterprets bindings for that category so that positions are expressed in a backward direction.
#

sub tell_backward_story{
    my ( $self, $cat ) = @_;
    my $bindings = $self->get_binding($cat);
    confess "Object $self does not belong to category $cat!"
        unless $bindings;
    $bindings->tell_backward_story($self);
}



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



# method: apply_blemish_at
# Applies a blemish at a given position
#
#    Arguments:
#    * $object
#    * $meto_type
#    * $position

sub apply_blemish_at{
    my ( $object, $meto_type, $position ) = @_;
    my ($index) = @{ $position->find_range( $object ) }; 
    #XXX assumption in prev line that a single item returned

    my @subobjects = @{ $items_of{ ident $object }};
    my $obj_at_pos = $subobjects[$index];
    my $blemished_object_at_pos = $meto_type->blemish( $obj_at_pos );
    my $metonym = SMetonym->new(
        { category => $meto_type->get_category,
          name     => $meto_type->get_name,
          info_loss => $meto_type->get_info_loss,
          starred   => $obj_at_pos,
          unstarred => $blemished_object_at_pos,
      },
            );
    ## $metonym
    ## $blemished_object_at_pos->get_structure()
    ## $blemished_object_at_pos->get_metonym
    $subobjects[$index] = $blemished_object_at_pos;
    my $ret =  SObject->create( @subobjects );
    ## $ret->get_structure()
    $ret->[$index]->set_metonym( $metonym );
    return $ret;
    # maybe make it belong to the category...
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



# method: has_structure_one_of
# returns true if one of several options valid
#

sub has_structure_one_of{
    my ( $self, @potential ) = @_;
    my $struct = $self->get_structure;
    ## $struct, $structure
    for (@potential) {
        if (SUtil::compare_deep($struct, $_)) {
            return 1;
        } 
    }
    return;

}



# method: describe_as
# Try to describe the object sa belonging to that category
#

sub describe_as{
    my ( $self, $cat ) = @_;
    my $is_of_cat = $self->is_of_category_p( $cat );

    if ($is_of_cat->[0]) {
        # okay, already a member
        return $is_of_cat->[1];
    }

    if (defined $is_of_cat->[0]) {
        # So: was not a member last we saw...
        #XXX should check using how old that decision was..
        ## and maybe return undef
    }

    my $bindings = $cat->is_instance( $self );

    return $bindings;

}

#
# subsection: relation management



# method: add_reln_from
# Add a relation from self
#
sub add_reln_from{
    my ( $self, $reln, $force ) = @_;
    my $id = ident $self;
    my $to = $reln->get_second;
    my $rel_hash_ref = $relns_from_of{$id};
    if (exists($rel_hash_ref->{$to}) and not $force) {
        confess("adding duplicate relation $reln to $self");
    }
    $rel_hash_ref->{$to} = $reln;
}

# method: add_reln_to
# Add a relation to self
#
sub add_reln_to{
    my ( $self, $reln, $force ) = @_;
    my $id = ident $self;
    my $from = $reln->get_first;
    ## $id, $from
    my $rel_hash_ref = $relns_to_of{$id};
    if (exists($rel_hash_ref->{$from}) and not $force) {
        confess("adding duplicate relation $reln to $self");
    }
    $rel_hash_ref->{$from} = $reln;
}



# method: add_reln
# add relation to object in appropriate hash.
#
sub add_reln{
    my ( $self, $reln, $force ) = @_;
    if ($reln->get_first() eq $self) {
        $self->add_reln_from( $reln, $force );
    } elsif ($reln->get_second() eq $self) {
        $self->add_reln_to( $reln, $force );
    } else {
        SErr->throw( "adding an unrelated reln to an object" );
    }
}



# method: remove_reln_from
# removes a relation from this object
#
sub remove_reln_from{
    my ( $self, $obj_or_rel ) = @_;
    my $id = ident $self;
    my $rel_hash_ref = $relns_from_of{$id};

    if ($obj_or_rel->isa("SObject")) {
        delete $rel_hash_ref->{$obj_or_rel};
    } else {
        delete $rel_hash_ref->{$obj_or_rel->get_second};
    }
}



# method: remove_reln_to
# removes a relation to this object
#
sub remove_reln_to{
    my ( $self, $obj_or_rel ) = @_;
    my $id = ident $self;
    my $rel_hash_ref = $relns_to_of{$id};

    if ($obj_or_rel->isa("SObject")) {
        delete $rel_hash_ref->{$obj_or_rel};
    } else {
        delete $rel_hash_ref->{$obj_or_rel->get_first};
    }
}



# method: remove_reln
# 
#
sub remove_reln{
    my ( $self, $reln ) = @_;
    my $id = ident $self;
    my ($f, $s) = $reln->get_ends;
    ### removing reln: "$reln from $self"
    if ($f eq $self) {
        delete $relns_from_of{$id}{$s};
    } elsif ($s eq $self) {
        delete $relns_to_of{$id}{$f};
    } else {
        SErr->throw('removing unrelated reln from object');
    }
}

sub get_relation{
    my ( $self, $other ) = @_;
    my $id = ident $self;
    ## $self, $other, $id
    ## $relns_from_of{$id}{$other}
    return $relns_from_of{$id}{$other} 
        || $relns_to_of{$id}{$other};
        
}



1;


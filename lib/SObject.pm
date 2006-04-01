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

use overload fallback => 1;

# variable: %group_p_of
#    Is this object a group? 
#     
#    It certainly is if there are several items, but can also be a group with a single item.
my %group_p_of : ATTR( :get<group_p>);


# variable: %metonym_of
#    The metonym associated with this object
my %metonym_of :ATTR( :get<metonym>);


# variable: %metonym_activeness_of
#    is metonym active?
my %metonym_activeness_of :ATTR( :get<metonym_activeness>);

# variable: %reln_other_of
my %reln_other_of :ATTR();


# variable: %underlying_reln_of
#    is the group based on some relation? undef if not, the relation otherwise
my %underlying_reln_of :ATTR( :get<underlying_reln>);

# variable: %direction_of
# xxx now using DIR::LEFT and DIR::RIGHT
#    direction: 1 for right, -1 for left; 0 if neither
#    Based on the left edge
my %direction_of :ATTR( :get<direction> :set<direction>  );




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
    $reln_other_of{$id} = {};
    $underlying_reln_of{$id} = undef;
    $metonym_activeness_of{$id} = 0;
    $metonym_of{$id}= undef;
    $direction_of{$id} = $opts_ref->{direction}|| DIR::UNKNOWN();
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
        return $package->new( { group_p => 1,
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

    if (@arguments == 1 ) { # and is an int
        return SElement->create($arguments[0], 0);
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
        unless (ref($object) eq "ARRAY") { confess("Got $object");
        }
        my @objects = @$object;
        if (@objects == 1) {
            return _create_or_int( $objects[0] );
        } else {
            return SObject->create(@objects);
        }
    } else {
        return SElement->create($object, 0);
    }
}


# method: quik_create
# Creates the object, adding metonyms as needed
#
#    For any subobject, if all of its elements are the same, adds the category-annotation for sameness group, and adds a metonymy

sub quik_create{
    my ( $package, $array_ref, @potential_cats ) = @_;
    my $object = $package->create(@$array_ref);
    my $id = ident $object;

    ## $object, $id

    unless ($object->isa("SElement")) {
      LOOP: for my $subobject (@{ $items_of{$id} }) {
            next if ref($subobject) eq "SElement";
            
            my $subid = ident $subobject;
            # now check if all elements in it are the same.
            my $parts_ref = $items_of{$subid};
            ## $subobject, $parts_ref
            my $count = scalar(@$parts_ref);
            my $first_part = $parts_ref->[0]->get_structure_string;
            
            for my $i (1..$count-1) {
                unless ($first_part eq $parts_ref->[$i]->get_structure_string) {
                    next LOOP;
                }
            }
            
            ## So a sameness group has been seen.
            ## $subobject->get_structure_string
            # print "# $S::SAMENESS\n";
            ## inst:  $S::SAMENESS->is_instance($subobject)
            $subobject->annotate_with_cat($S::SAMENESS);
            ## inst: $S::SAMENESS->is_instance($subobject)
            $subobject->annotate_with_metonym($S::SAMENESS, "each");
            $subobject->set_metonym_activeness(1);
        }
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
    my $bindings = $self->describe_as( $cat );

    SErr::NotOfCat->throw() unless $bindings;
    return $bindings;
}



# method: maybe_annotate_with_cat
# Similar to annotate_with_cat, except does not throw exception if the object cannot belong to the cat.
#
#    In fact, it does a add_non_cat in that situation.

*SObject::maybe_annotate_with_cat = *SObject::describe_as;

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

    if (my $o = $EVAL_ERROR) {
        if (UNIVERSAL::isa($o, 'SErr::MetonymNotAppicable')){
            
        } else {
            confess $o;
        }
    }    
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
    my @new_items = map { $_->get_structure()  } @$items_ref;
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
    my @items = map { @{ $_->get_flattened() } } @$items_ref;

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

sub boolify :BOOLIFY{
    my ( $self ) = @_;
    return $self;
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

multimethod can_be_seen_as => qw(SObject SObject) => sub {
    my ( $o1, $o2 ) = @_;
    can_be_seen_as($o1, $o2->get_structure);
};

multimethod can_be_seen_as => qw(SObject ARRAY) => sub {
    my ( $o1, $s ) = @_;
    my $id = ident $o1;
    my $self_structure = $o1->get_structure;

    return {} if SUtil::compare_deep($self_structure, $s);
    return {} if ($metonym_of{$id} and
                      SUtil::compare_deep(
                          $metonym_of{$id}->get_starred()->get_structure, 
                          $s));

    my $seen_as_parts_count = scalar(@$s);
    my $object_parts_ref = $o1->get_parts_ref;

    return unless scalar(@$object_parts_ref) == $seen_as_parts_count;

    my %return;
    for my $i (0 .. $seen_as_parts_count-1) {
        my $obj_part = $object_parts_ref->[$i];
        my $seen_as_part = $s->[$i];
        my $meto = _can_be_seen_as_no_rec($obj_part, $seen_as_part);
        unless (defined $meto) {
            return;
        }

        next unless $meto;
        $return{$i} = $meto;

    }
    return \%return;


};


multimethod can_be_seen_as => ('SObject', '#') => sub {
    my ( $o1, $int ) = @_;
    my $id = ident $o1;
    my $self_structure = $o1->get_structure;

    return {} if SUtil::compare_deep($self_structure, $int);
    return {} if ($metonym_of{$id} and
                      SUtil::compare_deep(
                          $metonym_of{$id}->get_starred()->get_structure, 
                          $int));

    my $object_parts_ref = $o1->get_parts_ref;

    return unless scalar(@$object_parts_ref) == 1;

    my %return;
    my $obj_part = $object_parts_ref->[0];
    my $seen_as_part = $int;
    my $meto = _can_be_seen_as_no_rec($obj_part, $seen_as_part);
    unless (defined $meto) {
        return;
    }

    $return{0} = $meto if $meto;
    return \%return;
};

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
    ## $meto
    return unless $meto;

    my $starred = $meto->get_starred;
    if (ref($starred) ne "SElement") {
        return;
    }

    return $starred->get_mag;
}




# multi: _can_be_seen_as_no_rec ( SObject, # )
# Can the object be seen as the int?
#
multimethod _can_be_seen_as_no_rec => ('SObject', '#') => sub {
    my ( $object, $int ) = @_;
    my $id = ident $object;
    $int = $int->get_structure() if ref($int) eq "SElement";

    ## _can_be_seen_as_no_rec: $object, $int
    ## $metonym_of{$id}
    if (SUtil::compare_deep($object->get_structure(), $int)) {
        return 0;
    } elsif ($metonym_of{$id} and $metonym_of{$id}->get_starred()->get_structure == $int) {
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
    UNIVERSAL::isa( $position, "SPos" ) or confess "Need SPos";

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
    my (@indices) = @{ $position->find_range( $object ) }; 
    #XXX assumption in prev line that a single item returned
    my @metonyms;

    my @subobjects = @{ $items_of{ ident $object }};
    my $meto_cat = $meto_type->get_category;
    my $meto_name = $meto_type->get_name;

    for my $index (@indices) {
        my $obj_at_pos = $subobjects[$index];
        my $blemished_object_at_pos = $meto_type->blemish( $obj_at_pos );
        my $metonym = SMetonym->new(
            { category => $meto_cat,
              name     => $meto_name,
              info_loss => $meto_type->get_info_loss,
              starred   => $obj_at_pos,
              unstarred => $blemished_object_at_pos,
          },
                );
        push @metonyms, $metonym;
        ## $metonym
        ## $blemished_object_at_pos->get_structure()
        ## $blemished_object_at_pos->get_metonym
        $subobjects[$index] = $blemished_object_at_pos;
    }
    my $ret =  SObject->create( @subobjects );
    ## $ret->get_structure()
    for my $index (@indices) {
        my $metonym = shift(@metonyms);
        $ret->[$index]->describe_as($meto_cat);
        $ret->[$index]->set_metonym( $metonym );
        $ret->[$index]->set_metonym_activeness(1);
    }
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
    if ($bindings) {
        $self->add_category($cat, $bindings);
    }

    return $bindings;

}

#
# subsection: relation management



# method: _get_other_end_of_reln
# 
#
sub _get_other_end_of_reln{
    my ( $self, $reln ) = @_;
    my($f, $s)= $reln->get_ends();
    return $s if $f eq $self;
    return $f if $s eq $self;
    SErr->throw("relation error: not an end");
}



# method: add_reln
# 
#
sub add_reln{
    my ( $self, $reln, $force ) = @_;
    my $id = ident $self;
    my $other = $self->_get_other_end_of_reln($reln);
    
    if (exists( $reln_other_of{$id}{$other}) and not($force)) {
        SErr->throw("duplicate reln being added");
    }

    $reln_other_of{$id}{$other} = $reln;
}



# method: remove_reln
# 
#
sub remove_reln{
    my ( $self, $reln ) = @_;
    my $id = ident $self;

    my $other = $self->_get_other_end_of_reln($reln);
    delete $reln_other_of{$id}{$other};
}


sub get_relation{
    my ( $self, $other ) = @_;
    my $id = ident $self;

    return $reln_other_of{$id}{$other}
        if exists $reln_other_of{$id}{$other};
    return;
}

sub set_underlying_reln :CUMULATIVE{
    my ( $self, $reln ) = @_;
    my $id = ident $self;
    
    $underlying_reln_of{$id} = $reln;
}

sub set_metonym{
    my ( $self, $meto ) = @_;
    my $id = ident $self;

    SErr->throw("Metonym must be an SObject! Got: " . $meto->get_starred )
        unless UNIVERSAL::isa($meto->get_starred, "SObject");
    $metonym_of{$id} = $meto;
}


sub set_metonym_activeness{
    my ( $self, $value ) = @_;
    my $id = ident $self;
    
    if ($value) {
        return if $metonym_activeness_of{$id};
        unless ($metonym_of{$id}) {
            SErr->throw("Cannot set_metonym_activeness without a metonym");
        }
        $metonym_activeness_of{$id} = 1;
    } else {
        $metonym_activeness_of{$id} = 0;
    }

}

sub get_effective_object{
    my ( $self ) = @_;
    my $id = ident $self;

    return $self unless $metonym_activeness_of{$id};
    return $metonym_of{$id}->get_starred;
}

sub get_structure_string{
    my ( $self ) = @_;
    my $struct = $self->get_structure;
    if (ref $struct) {
        return _get_structure_string($struct);
    } else {
        return $struct;
    }
}

sub _get_structure_string{
    my ( $struct ) = @_;
    if (ref $struct) {
        return "(" .  join(",", map { _get_structure_string($_) } @$struct).")";
    } else {
        return $struct;
    }
}

sub get_span{
    my ( $self ) = @_;
    return List::Util::sum( map { $_->get_span } @$self );
}



1;


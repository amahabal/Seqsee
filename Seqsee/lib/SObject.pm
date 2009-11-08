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
use base qw{SInstance SHistory SFasc};
use overload (fallback => 1);

multimethod 'FindTransform';
multimethod 'ApplyTransform';

my %items_of : ATTR( :get<parts_ref> );    #    The items of this object.
my %group_p_of : ATTR( :get<group_p> :set<group_p>);     #    Is this object a group?
                                           # Can also be true for a single item.
my %metonym_of : ATTR( :get<metonym>);     #    The metonym associated with this object
my %metonym_activeness_of : ATTR( :get<metonym_activeness>);           # Bool: is it active?
my %is_a_metonym_of : ATTR( :get<is_a_metonym> :set<is_a_metonym>);    #
my %direction_of : ATTR( :get<direction> :set<direction>  );           # Direction: see S::Dir.
my %reln_scheme_of : ATTR( :get<reln_scheme> :set<reln_scheme>  );     # See S::Reln_Scheme

# variable: %reln_other_of
# XXX(Assumption): [2006/09/16] Only a single reln between two objects possible
# this way.
my %reln_other_of : ATTR();

# variable: %underlying_reln_of
#    is the group based on some relation? undef if not, the relation otherwise
my %underlying_reln_of : ATTR( :get<underlying_reln>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    die "Need group_p" unless exists $opts_ref->{group_p};

    $items_of{$id}              = $opts_ref->{items} or die "Need items";
    $group_p_of{$id}            = $opts_ref->{group_p};
    $reln_other_of{$id}         = {};
    $underlying_reln_of{$id}    = undef;
    $metonym_activeness_of{$id} = 0;
    $metonym_of{$id}            = undef;
    $direction_of{$id}          = $opts_ref->{direction} || DIR::UNKNOWN();
    $reln_scheme_of{$id}        = "";
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

sub create {
    my $package = shift;

    my @arguments = @_;

    if ( !@arguments ) {
        return $package->new(
            {   group_p => 1,
                items   => [],
            }
        );
    }

    my @original_arguments = @arguments;
    my @categories_of_arguments = map {
        my @cats;
        if (UNIVERSAL::isa($_, "SObject")) {
            @cats = @{ $_->get_categories() };
        }
        \@cats;
    } @arguments;

    # Convert Sobjects to array refs...
    @arguments = map { UNIVERSAL::isa( $_, "SObject" ) ? $_->get_structure() : $_ } @arguments;

    if ( @arguments == 1 and ref( $arguments[0] ) ) {

        # Single argument which is an array ref
        return $package->create( @{ $original_arguments[0] } );
    }

    if ( @arguments == 1 ) {    # and is an int
        return SElement->create( $arguments[0], 0 );
    }

    # Finally, convert all arrays to objects, too!
    @arguments = map { CreateObjectFromStructure($_) } @arguments;
    for my $idx (0..scalar(@arguments)-1) {
        for my $cat (@{$categories_of_arguments[$idx]}) {
            $arguments[$idx]->describe_as($cat);
        }
    }

    my $group_p = ( @arguments == 1 ) ? 0 : 1;

    return $package->new(
        {   items   => \@arguments,
            group_p => $group_p,
        }
    );

}

# method: CreateObjectFromStructure
# creates the object, or just returns int

sub CreateObjectFromStructure {
    my $object = shift;

    if ( ref $object ) {

        # An array ref..
        unless ( ref($object) eq "ARRAY" ) {
            confess("Got $object");
        }
        my @objects = @$object;
        if ( @objects == 1 ) {
            return CreateObjectFromStructure( $objects[0] );
        }
        else {
            return SObject->create(@objects);
        }
    }
    else {
        return SElement->create( $object, 0 );
    }
}

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

sub annotate_with_cat {
    my ( $self, $cat ) = @_;
    my $bindings = $self->describe_as($cat);

    SErr::NotOfCat->throw() unless $bindings;
    return $bindings;
}

# method: get_structure
# returns the structure, a deep array of integers
#
#    Returns an array ref of integers and other array refs of integers, unblessed.

sub get_structure {
    my ($self) = shift;
    my $id = ident $self;

    my $items_ref = $items_of{$id};
    my @new_items = map { $_->get_structure() } @$items_ref;
    return \@new_items;

}

# method: get_flattened
# get a flattened version
#
#    Returns an arrayref of integers.

sub get_flattened {
    my ($self) = @_;
    my $id = ident $self;

    my $items_ref = $items_of{$id};
    my @items = map { @{ $_->get_flattened() } } @$items_ref;

    return \@items;
}

# method: get_parts_count
# how many parts does the object have?
#

sub get_parts_count {
    my $id = ident shift;
    return scalar( @{ $items_of{$id} } );
}

# method: arrayify
# Get the numbered part, 0  indexed
#
#    automatically used when object is treated as an array ref

sub arrayify : ARRAYIFY {
    my $self = shift;
    return $items_of{ ident $self};
}

sub boolify : BOOLIFY {
    my ($self) = @_;
    return $self;
}

# method: tell_forward_story
# Given a category, reinterprets bindings for that category so that positions are expressed in a forward direction.
#

sub tell_forward_story {
    my ( $self, $cat ) = @_;
    my $bindings = $self->GetBindingForCategory($cat);
    confess "Object $self does not belong to category " . $cat->get_name()
        unless $bindings;
    $self->AddHistory( "Forward story telling for " . $cat->get_name );
    $bindings->tell_forward_story($self);
}

# method: tell_backward_story
# Given a category, reinterprets bindings for that category so that positions are expressed in a backward direction.
#

sub tell_backward_story {
    my ( $self, $cat ) = @_;
    my $bindings = $self->GetBindingForCategory($cat);
    confess "Object $self does not belong to category $cat!"
        unless $bindings;
    $self->AddHistory( "Backward story telling for " . $cat->get_name );
    $bindings->tell_backward_story($self);
}

sub TellDirectedStory{
    my ( $self, $cat, $position_mode ) = @_;
    my $bindings = $self->GetBindingForCategory($cat);
    my $self_as_text = $self->as_text();
    confess "Object $self ($self_as_text) does not belong to category $cat!"
        unless $bindings;
    $bindings->TellDirectedStory($self, $position_mode);
}


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

    if ( @$range == 1 ) {
        return $ret[0];
    }

    return \@ret;
}

# method: get_at_position
# Returns subobject at given position
#

sub get_at_position {    #( $self: $position )
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

sub apply_blemish_at {
    my ( $object, $meto_type, $position ) = @_;
    my (@indices) = @{ $position->find_range($object) };

    #XXX assumption in prev line that a single item returned
    my @metonyms;

    my @subobjects = @{ $items_of{ ident $object } };
    my $meto_cat   = $meto_type->get_category;
    my $meto_name  = $meto_type->get_name;

    for my $index (@indices) {
        my $obj_at_pos              = $subobjects[$index];
        my $blemished_object_at_pos = $meto_type->blemish($obj_at_pos);
        my $metonym                 = SMetonym->new(
            {   category  => $meto_cat,
                name      => $meto_name,
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
    my $ret = SObject->create(@subobjects);
    ## $ret->get_structure()
    for my $index (@indices) {
        my $metonym = shift(@metonyms);
        $ret->[$index]->describe_as($meto_cat);
        $ret->[$index]->SetMetonym($metonym);
        $metonym->get_starred()->set_is_a_metonym( $ret->[$index] );
        $ret->[$index]->SetMetonymActiveness(1);
    }
    return $ret;

    # maybe make it belong to the category...
}

#
# subsection: Testing utilities(methods)

# method: structure_ok
# checks if structure matches the argument, and cals ok or nok
#

sub structure_ok {
    my ( $self, $structure ) = @_;
    my $struct = $self->get_structure;
    ## $struct, $structure
    if ( SUtil::compare_deep( $struct, $structure ) ) {
        Test::More::ok( 1, "structure ok" );
    }
    else {
        Test::More::ok( 0, "structure ok" );
    }
}

# method: has_structure_one_of
# returns true if one of several options valid
#

sub has_structure_one_of {
    my ( $self, @potential ) = @_;
    my $struct = $self->get_structure;
    ## $struct, $structure
    for (@potential) {
        if ( SUtil::compare_deep( $struct, $_ ) ) {
            return 1;
        }
    }
    return;

}

# method: describe_as
# Try to describe the object sa belonging to that category
#

sub describe_as {
    my ( $self, $cat ) = @_;
    my $is_of_cat = $self->is_of_category_p($cat);

    return $is_of_cat if $is_of_cat;

    my $bindings = $cat->is_instance($self);
    if ($bindings) {
        ## describe_as succeeded!
        $self->add_category( $cat, $bindings );
    }

    return $bindings;
}

# method: describe_as
# Try to describe the object sa belonging to that category
#

sub redescribe_as {
    my ( $self, $cat ) = @_;
    my $bindings = $cat->is_instance($self);
    if ($bindings) {
        ## describe_as succeeded!
        $self->AddHistory( "redescribe as instance of category " . $cat->get_name . " succeded" );
        $self->add_category( $cat, $bindings );
    }
    else {
        $self->AddHistory( "redescribe as instance of category " . $cat->get_name . " failed" );
        $self->remove_category($cat);
    }

    return $bindings;

}

# XXX(Board-it-up): [2007/02/03] changing reln to ruleapp!
sub set_underlying_ruleapp : CUMULATIVE {
    my ( $self, $reln ) = @_;
    $reln or confess "Cannot set underlying relation to be an undefined value!";
    my $id = ident $self;

    if (UNIVERSAL::isa($reln, "SRelation") or UNIVERSAL::isa($reln, 'Transform')) {
        $reln = SRule->create( $reln ) or return;
    }
    my $ruleapp;
    if (UNIVERSAL::isa($reln, "SRule")) {
        $ruleapp = $reln->CheckApplicability({
            objects => [@$self],
            direction => $self->get_direction(),
        }); # could be undef.
    } else {
        confess "Funny argument $reln to set_underlying_ruleapp!";
    }

    $self->AddHistory("Underlying relation set: $ruleapp ");
    $underlying_reln_of{$id} = $ruleapp;
}


sub get_structure_string {
    my ($self) = @_;
    my $struct = $self->get_structure;
    SUtil::StructureToString($struct);
}

sub GetAnnotatedStructureString {
    my ( $self ) = @_;
    my $id = ident $self;

    my $body;
    if ($self->isa('SElement')) {
        $body = $self->get_mag;
    } else {
        my @items = @{$items_of{$id}};
        $body = '[' . join(', ', map { $_->GetAnnotatedStructureString } @items) .']';
    }

    if ($metonym_activeness_of{$id}) {
        my $meto_structure_string = $self->GetEffectiveObject()->get_structure_string();
        $body .= " --*-> $meto_structure_string";
    }

    return $body;
}


# XXX(Assumption): [2006/09/16] Parts are non-overlapping.
sub get_span {
    my ($self) = @_;
    return List::Util::sum( map { $_->get_span } @$self );
}

sub apply_reln_scheme {
    my ( $self, $scheme ) = @_;
    return unless $scheme;
    if ( $scheme == RELN_SCHEME::CHAIN() ) {
        my $parts_ref = $self->get_parts_ref;
        my $cnt       = scalar(@$parts_ref);
        for my $i ( 0 .. ( $cnt - 2 ) ) {
            my ( $a, $b ) = ( $parts_ref->[$i], $parts_ref->[ $i + 1 ] );
            next if $a->get_relation($b);
            my $transform = FindTransform( $a, $b );
            my $rel = SRelation->new({first=>$a, second=>$b,type=>$transform});
            $rel->insert() if $rel;
        }
        $self->AddHistory("Relation scheme \"chain\" applied");
    }
    else {
        confess "Relation scheme $scheme not implemented";
    }
}

# XXX(Board-it-up): [2006/09/16] Recalculation ignores categories.
# XXX(Assumption): [2006/09/16] Unique relation between two objects.

sub recalculate_categories {
    my ($self) = @_;
    my $id = ident $self;

    my $cats = $self->get_categories();
    for my $cat (@$cats) {
        $self->redescribe_as($cat);
    }

}

sub get_pure {
    my ($self) = @_;
    return SLTM::Platonic->create( $self->get_structure_string() );
}

sub HasAsItem{
    my ( $self, $item ) = @_;
    for (@$self) {
        return 1 if $_ eq $item;
    }
    return 0;
}

sub SElement::HasAsPartDeep{
    my ( $self, $item ) = @_;
    return $self eq $item;
}

sub HasAsPartDeep{
    my ( $self, $item ) = @_;
    for (@$self) {
        return 1 if $_ eq $item;
        return 1 if $_->HasAsPartDeep($item);
    }
    return 0;
}


# ###################################################################
# VERSION POST REFACTORING

# METONYM MANAGEMENT
sub SetMetonym {
    my ( $self, $meto ) = @_;
    my $id      = ident $self;
    my $starred = $meto->get_starred();
    SErr->throw("Metonym must be an SObject! Got: $starred")
      unless UNIVERSAL::isa( $starred, "SObject" );
    $is_a_metonym_of{ ident($starred) } = $self;
    $metonym_of{$id} = $meto;
}

sub SetMetonymActiveness {
    my ( $self, $value ) = @_;
    my $id = ident $self;

    if ($value) {
        return if $metonym_activeness_of{$id};
        unless ( $metonym_of{$id} ) {
            SErr->throw("Cannot SetMetonymActiveness without a metonym");
        }
        $self->AddHistory("Metonym activeness turned on");
        $metonym_activeness_of{$id} = 1;
    }
    else {
        $self->AddHistory("Metonym activeness turned off");
        $metonym_activeness_of{$id} = 0;
    }
}

sub GetEffectiveObject {
    my ($self) = @_;
    my $id = ident $self;

    return $self unless $metonym_activeness_of{$id};
    return $metonym_of{$id}->get_starred();
}

sub GetEffectiveStructure {
    my ( $self ) = @_;
    return [ map { $_->GetEffectiveObject()->get_structure } @$self ];
}

sub SElement::GetEffectiveStructure{
    my ( $self ) = @_;
    return $self->get_mag();
}

sub GetEffectiveStructureString{
    my ( $self ) = @_;
    return SUtil::StructureToString($self->GetEffectiveStructure());
}

sub GetUnstarred{
    my ( $self ) = @_;
    my $id = ident $self;
    return $is_a_metonym_of{$id} || $self;
}

sub AnnotateWithMetonym {
    my ( $self, $cat, $name ) = @_;
    my $is_of_cat = $self->is_of_category_p($cat);

    unless ( $is_of_cat ) {
        $self->annotate_with_cat($cat);
    }

    my $meto = $cat->find_metonym( $self, $name );
    SErr::MetonymNotAppicable->throw() unless $meto;

    $self->AddHistory( "Added metonym \"$name\" for cat " . $cat->get_name() );
    $self->SetMetonym($meto);
}

sub MaybeAnnotateWithMetonym {
    my ( $self, $cat, $name ) = @_;
    eval { $self->AnnotateWithMetonym( $cat, $name ) };

    if ( my $o = $EVAL_ERROR ) {
        confess $o unless ( UNIVERSAL::isa( $o, 'SErr::MetonymNotAppicable' ) );
    }
}

sub IsThisAMetonymedObject {
    my ( $self ) = @_;
    my $id = ident $self;
    my $is_a_metonym_of = $is_a_metonym_of{$id};
    return 0 if (not($is_a_metonym_of) or $is_a_metonym_of eq $self);
    return 1;
}

sub ContainsAMetonym {
    my ( $self ) = @_;
    my $id = ident $self;
    return 1 if $self->IsThisAMetonymedObject;
    for (@$self) {
        return 1 if $_->ContainsAMetonym;
    }
    return 0;
}
sub SElement::ContainsAMetonym {
    return 0;
}
# #################################
# RELATION MANAGEMENT
# Relevant variables:
# %reln_other_of

sub AddRelation {
    my ( $self, $reln ) = @_;
    my $id    = ident $self;
    my $other = $self->_get_other_end_of_reln($reln);

    if ( exists( $reln_other_of{$id}{$other} ) ) {
        SErr->throw("duplicate reln being added");
    }
    $self->AddHistory( "added reln to " . $other->get_bounds_string() );
    $reln_other_of{$id}{$other} = $reln; # The other direction is handled by whoever calls this.
}

sub RemoveRelation {
    my ( $self, $reln ) = @_;
    my $id = ident $self;

    my $other = $self->_get_other_end_of_reln($reln);
    $self->AddHistory( "removed reln to " . $other->get_bounds_string() );
    delete $reln_other_of{$id}{$other};
}

sub RemoveAllRelations{
    my ( $self ) = @_;
    my @relations = values %{$reln_other_of{ident $self}};
    for (@relations) {
        $_->uninsert();
    }
}


sub get_relation {
    my ( $self, $other ) = @_;
    my $id = ident $self;

    return $reln_other_of{$id}{$other}
        if exists $reln_other_of{$id}{$other};
    return;
}

sub _get_other_end_of_reln {
    my ( $self, $reln ) = @_;
    my ( $f,    $s )    = $reln->get_ends();
    return $s if $f eq $self;
    return $f if $s eq $self;
    SErr->throw("relation error: not an end");
}

sub recalculate_relations {
    my ($self) = @_;
    my %hash = %{$reln_other_of{ ident $self}};
    while ( my ( $k, $v ) = each %hash ) {
        my $type = $v->get_type();
        my $new_type = $type->get_category()->FindTransformForCat( $v->get_ends );

        if ($new_type) {
            my ($f, $s) = $v->get_ends;
            my $new_rel = SRelation->new({first => $f, second => $s, type => $new_type});
            $v->uninsert;
            $new_rel->insert;
        }
        else {
            $v->uninsert;
            #main::message("A relation no longer valid, removing!");
        }
    }
}

sub as_text {
    my ($self) = @_;
    my $structure_string = $self->get_structure_string();
    return "SObject $structure_string";
}

multimethod CanBeSeenAs => ( '#', '#' ) => sub {
    my ( $a, $b ) = @_;
    return ResultOfCanBeSeenAs->newUnblemished() if $a == $b;
    return ResultOfCanBeSeenAs->NO();
};

multimethod CanBeSeenAs => ('SObject', 'SObject') => sub {
    my ( $obj, $structure ) = @_;
    return CanBeSeenAs($obj, $structure->get_structure());
};


multimethod CanBeSeenAs => ( 'SObject', '#' ) => sub {
    my ( $object, $int ) = @_;
    my $lit_or_meto = $object->CanBeSeenAs_Literal0rMeto($int);
    ## lit_or_meto(elt): $lit_or_meto
    return $lit_or_meto if defined $lit_or_meto;
    return ResultOfCanBeSeenAs::NO();

};

multimethod CanBeSeenAs => ( 'SObject', 'ARRAY' ) => sub {
    my ( $object, $structure ) = @_;
    my $meto_activeness = $object->get_metonym_activeness();
    my $metonym         = $object->get_metonym();
    my $starred         = $metonym ? $metonym->get_starred() : undef;
    ## before active meto
    if ($meto_activeness) {
        my $meto_seen_as = $object->CanBeSeenAs_Meto($structure, $starred, $metonym);
        return $meto_seen_as if defined $meto_seen_as;
    }

    ## before by part
    my $part_seen_as = $object->CanBeSeenAs_ByPart($structure);
    return $part_seen_as if defined $part_seen_as;

    ## before meto
    if ($metonym) {
        my $meto_seen_as = $object->CanBeSeenAs_Meto($structure, $starred, $metonym);
        return $meto_seen_as if defined $meto_seen_as;
    }
    ## failed CanBeSeenAs
    return ResultOfCanBeSeenAs::NO();
};

sub CanBeSeenAs_ByPart{
    my ( $object, $structure ) = @_;
    my $seen_as_part_count = scalar(@$structure);
    ## $seen_as_part_count
    return 
      unless scalar(@$object) == $seen_as_part_count;
    my %blemishes;
    my $obj_part_ref = $object->get_parts_ref();
    for my $i ( 0 .. $seen_as_part_count - 1 ) {
        my $obj_part            = $obj_part_ref->[$i];
        my $seen_as_part        = $structure->[$i];
        my $part_can_be_seen_as = CanBeSeenAs( $obj_part, $seen_as_part );
        ## obj, seen_as: $obj_part->as_text(), $seen_as_part, $part_can_be_seen_as
        return unless $part_can_be_seen_as;
        return if $part_can_be_seen_as->ArePartsBlemished();
        ## is part blemished: $part_can_be_seen_as->IsBlemished()
        next unless $part_can_be_seen_as->IsBlemished();
        $blemishes{$i} = $part_can_be_seen_as->GetEntireBlemish();
    }
    ## %blemishes
    return ResultOfCanBeSeenAs->newUnblemished() unless %blemishes;
    return ResultOfCanBeSeenAs->newByPart( \%blemishes );    
}

sub CanBeSeenAs_Meto{
    scalar(@_) == 4 or confess;
    my ( $object, $structure, $starred, $metonym ) = @_;
    return ResultOfCanBeSeenAs->newEntireBlemish($metonym)
        if SUtil::compare_deep( $starred->get_structure(), $structure );
}

sub CanBeSeenAs_Literal{
    my ( $object, $structure ) = @_;
    return ResultOfCanBeSeenAs->newUnblemished()
      if SUtil::compare_deep( $object->get_structure(), $structure );    
}


sub CanBeSeenAs_Literal0rMeto {
    my ( $object, $structure ) = @_;
    $structure = $structure->get_structure()
      if UNIVERSAL::isa( $structure, 'SObject' );

    my $meto_activeness = $object->get_metonym_activeness();
    my $metonym         = $object->get_metonym();
    my $starred         = $metonym ? $metonym->get_starred() : undef;

    if ($meto_activeness) {
        ## active metonym
        return ResultOfCanBeSeenAs->newEntireBlemish($metonym)
            if SUtil::compare_deep( $starred->get_structure(), $structure );
    }

    return ResultOfCanBeSeenAs->newUnblemished()
      if SUtil::compare_deep( $object->get_structure(), $structure );

    if ($metonym) {
        ## inactive metonym
        return ResultOfCanBeSeenAs->newEntireBlemish($metonym)
          if SUtil::compare_deep( $starred->get_structure(), $structure );
    }

#if we get here, it means that the metonym, if present,is not active. and also that the metonym or the object itself cannot be seen as structure
    return;

}

# Returns active metonyms, for use in, for example, bindings creation. 
sub GetEffectiveSlippages {
    my ( $self ) = @_;
    my @parts = @$self;
    my $parts_count = scalar(@parts);
    my $return = {};
    for my $idx (0..$parts_count-1) {
        my $id = ident $parts[$idx];
        next unless $metonym_activeness_of{$id};
        $return->{$idx} = $metonym_of{$id};
    }
    return $return;
}


1;



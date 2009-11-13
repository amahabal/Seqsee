use MooseX::Declare;

class Seqsee::Object {
  with 'Seqsee::Instance';
  with 'Seqsee::History';
  use overload(
    '~~' => sub { $_[0] eq $_[1] },
    '@{}'    => sub { $_[0]->items },
    'bool'   => sub { 1 },
    fallback => 1,
  );
  use English qw(-no_match_vars);
  use Class::Multimethods;
  has items => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Seqsee::Object]',
    default   => sub { [] },
    provides  => {
      'push'  => '_insert_items',
      'get'   => 'item',
      'count' => 'get_parts_count',
    }
  );

  has group_p => (
    is  => 'rw',
    isa => 'Bool',
  );

  has relation_to => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[SRelation]',
    default   => sub { {} },
    provides  => {
      'get'    => 'get_relation_to',
      'set'    => 'set_relation_to',
      'exists' => 'has_relation_to',
      'delete' => 'remove_relation_to',
      'values' => 'all_relations',
    }
  );

  has underlying_relation => (
    is  => 'rw',
    isa => 'SRuleApp',
  );

  method get_underlying_reln() {
    $self->underlying_relation
  }

  has metonym => (
    is  => 'rw',
    isa => 'Any',
  );

  has is_metonym_of => (
    is  => 'rw',
    isa => 'Any',
  );

  has metonym_activeness => (
    is  => 'rw',
    isa => 'Bool',
  );

  has strength => (
    is  => 'rw',
    isa => 'Num',
  );

  method get_strength() {
    $self->strength;
  }

  method get_parts_ref() {
    $self->items;
  }

  sub create {
    my $package = shift;

    my @arguments = @_;

    if ( !@arguments ) {
      return $package->new(
        group_p => 1,
        items   => [],
      );
    }

    my @original_arguments      = @arguments;
    my @categories_of_arguments = map {
      my @cats;
      if ( UNIVERSAL::isa( $_, "Seqsee::Object" ) ) {
        @cats = @{ $_->get_categories() };
      }
      \@cats;
    } @arguments;

    # Convert Seqsee::Objects to array refs...
    @arguments =
    map { UNIVERSAL::isa( $_, "Seqsee::Object" ) ? $_->get_structure() :$_ }
    @arguments;

    if ( @arguments == 1 and ref( $arguments[0] ) ) {

      # Single argument which is an array ref
      return $package->create( @{ $original_arguments[0] } );
    }

    if ( @arguments == 1 ) {    # and is an int
      return Seqsee::Element->create( $arguments[0], 0 );
    }

    # Finally, convert all arrays to objects, too!
    @arguments = map { CreateObjectFromStructure($_) } @arguments;
    for my $idx ( 0 .. scalar(@arguments) - 1 ) {
      for my $cat ( @{ $categories_of_arguments[$idx] } ) {
        $arguments[$idx]->describe_as($cat);
      }
    }

    my $group_p = ( @arguments == 1 ) ? 0 :1;

    return $package->new(
      {
        items   => \@arguments,
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
        return Seqsee::Object->create(@objects);
      }
    }
    else {
      return Seqsee::Element->create( $object, 0 );
    }
  }

  method annotate_with_cat($cat) {
    my $bindings = $self->describe_as($cat);

    SErr::NotOfCat->throw() unless $bindings;
    return $bindings;
  }

  method get_structure() {
    [ map { $_->get_structure() } @{ $self->items } ];
  }

  method get_flattened() {
    [ map { @{ $_->get_flattened() } } @{ $self->items } ];
  }

  method tell_forward_story($cat) {
    my $bindings = $self->GetBindingForCategory($cat);
    confess "Object $self does not belong to category " . $cat->get_name()
    unless $bindings;
    $self->AddHistory( "Forward story telling for " . $cat->get_name );
    $bindings->tell_forward_story($self);
  }

  method tell_backward_story($cat) {
    my $bindings = $self->GetBindingForCategory($cat);
    confess "Object $self does not belong to category $cat!"
    unless $bindings;
    $self->AddHistory( "Backward story telling for " . $cat->get_name );
    $bindings->tell_backward_story($self);
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

  method get_subobj_given_range($range) {
    my @ret;

    for (@$range) {
      my $what = $self->item($_) // SErr::Pos::OutOfRange->throw();
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

  method get_at_position($position) {
    my $range = $position->find_range($self);
    return $self->get_subobj_given_range($range);
  }

  method apply_blemish_at( $meto_type, $position ) {
    my $object = $self;
    my (@indices) = @{ $position->find_range($object) };

    #XXX assumption in prev line that a single item returned
    my @metonyms;

    my @subobjects = @{ $self->items };
    my $meto_cat   = $meto_type->get_category;
    my $meto_name  = $meto_type->get_name;

    for my $index (@indices) {
      my $obj_at_pos              = $subobjects[$index];
      my $blemished_object_at_pos = $meto_type->blemish($obj_at_pos);
      my $metonym                 = SMetonym->new(
        {
          category  => $meto_cat,
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
    my $ret = Seqsee::Object->create(@subobjects);
    ## $ret->get_structure()
    for my $index (@indices) {
      my $metonym = shift(@metonyms);
      $ret->[$index]->describe_as($meto_cat);
      $ret->[$index]->SetMetonym($metonym);
      $metonym->get_starred()->is_metonym_of( $ret->[$index] );
      $ret->[$index]->SetMetonymActiveness(1);
    }
    return $ret;

    # maybe make it belong to the category...
  }

  # method: describe_as
  # Try to describe the object sa belonging to that category
  #

  method describe_as($cat) {
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

  method redescribe_as($cat) {
    my $bindings = $cat->is_instance($self);
    if ($bindings) {
      ## describe_as succeeded!
      $self->AddHistory(
        "redescribe as instance of category " . $cat->get_name . " succeded" );
      $self->add_category( $cat, $bindings );
    }
    else {
      $self->AddHistory(
        "redescribe as instance of category " . $cat->get_name . " failed" );
      $self->remove_category($cat);
    }

    return $bindings;

  }

  method get_structure_string() {
    my $struct = $self->get_structure;
    SUtil::StructureToString($struct);
  }

  method GetAnnotatedStructureString() {
    my $body;
    if ( $self->isa('Seqsee::Element') ) {
      $body = $self->get_mag;
    }
    else {
      $body = '['
      . join( ', ', map { $_->GetAnnotatedStructureString } @{ $self->items } )
      . ']';
    }

    if ( $self->metonym_activeness ) {
      my $meto_structure_string =
      $self->GetEffectiveObject()->get_structure_string();
      $body .= " --*-> $meto_structure_string";
    }

    return $body;
  }

  # XXX(Assumption): [2006/09/16] Parts are non-overlapping.
  method get_span() {
    return List::Util::sum( map { $_->get_span } @{ $self->items } );
  }

  method apply_reln_scheme($scheme) {
    return
    unless $scheme;
    if ( $scheme == RELN_SCHEME::CHAIN() ) {
      my $parts_ref = $self->get_parts_ref;
      my $cnt       = scalar(@$parts_ref);
      for my $i ( 0 .. ( $cnt - 2 ) ) {
        my ( $a, $b ) = ( $parts_ref->[$i], $parts_ref->[ $i + 1 ] );
        next if $a->get_relation($b);
        my $transform = FindTransform( $a, $b );
        my $rel =
        SRelation->new( { first => $a, second => $b, type => $transform } );
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

  method recalculate_categories() {
    my $cats = $self->get_categories();
    for my $cat (@$cats) {
      $self->redescribe_as($cat);
    }
  }

  method get_pure() {
    return SLTM::Platonic->create( $self->get_structure_string() );
  }

  method HasAsItem($item) {
    return $item ~~ $self->items;
  }

  sub Seqsee::Element::HasAsPartDeep {
    my ( $self, $item ) = @_;
    return $self eq $item;
  }

  method HasAsPartDeep($item) {
    for ( @{ $self->items } )
    {
      return 1 if $_ eq $item;
      return 1 if $_->HasAsPartDeep($item);
    }
    return 0;
  }

  method SetMetonym($meto) {
    my $starred = $meto->get_starred();
    SErr->throw("Metonym must be an Seqsee::Object! Got: $starred")
    unless UNIVERSAL::isa( $starred, "Seqsee::Object" );
    $starred->is_metonym_of($self);
    $self->metonym($meto);
  }

  method SetMetonymActiveness($value) {
    if ($value)
    {
      return if $self->metonym_activeness();
      unless ( $self->metonym ) {
        SErr->throw("Cannot SetMetonymActiveness without a metonym");
      }
      $self->AddHistory("Metonym activeness turned on");
      $self->metonym_activeness(1);
    }
    else {
      $self->AddHistory("Metonym activeness turned off");
      $self->metonym_activeness(0);
    }
  }

  method GetEffectiveObject() {
    return $self
    unless $self->metonym_activeness;
    return $self->metonym->get_starred();
  }

  method GetEffectiveStructure() {
    return [
      map { $_->GetEffectiveObject()->get_structure } @{ $self->items }
    ];
  }

  sub Seqsee::Element::GetEffectiveStructure {
    my ($self) = @_;
    return $self->get_mag();
  }

  method GetEffectiveStructureString() {
    return SUtil::StructureToString( $self->GetEffectiveStructure() );
  }

  method GetUnstarred() {
    return $self->is_metonym_of() // $self;
  }

  method AnnotateWithMetonym( $cat, $name ) {
    my $is_of_cat = $self->is_of_category_p($cat);

    unless ($is_of_cat) {
      $self->annotate_with_cat($cat);
    }

    my $meto = $cat->find_metonym( $self, $name );
    SErr::MetonymNotAppicable->throw() unless $meto;

    $self->AddHistory( "Added metonym \"$name\" for cat " . $cat->get_name() );
    $self->SetMetonym($meto);
  }

  method MaybeAnnotateWithMetonym( $cat, $name ) {
    eval { $self->AnnotateWithMetonym( $cat, $name ) };

    if ( my $o = $EVAL_ERROR ) {
      confess $o unless ( UNIVERSAL::isa( $o, 'SErr::MetonymNotAppicable' ) );
    }
  }

  method IsThisAMetonymedObject() {
    my $is_metonym_of = $self->is_metonym_of;
    return 0 if ( not($is_metonym_of) or $is_metonym_of eq $self );
    return 1;
  }

  method ContainsAMetonym() {
    return 1
    if $self->IsThisAMetonymedObject;
    for ( @{ $self->items } ) {
      return 1 if $_->ContainsAMetonym;
    }
    return 0;
  }

  sub Seqsee::Element::ContainsAMetonym {
    return 0;
  }

  # #################################
  # RELATION MANAGEMENT
  # Relevant variables:
  # %reln_other_of

  method AddRelation($reln) {
    my $other = $self->_get_other_end_of_reln($reln);

    if ( $self->has_relation_to($other) ) {
      SErr->throw("duplicate reln being added");
    }
    $self->AddHistory( "added reln to " . $other->get_bounds_string() );
    $self->set_relation_to( $other, $reln );
  }

  method RemoveRelation($reln) {
    my $other = $self->_get_other_end_of_reln($reln);
    $self->AddHistory( "removed reln to " . $other->get_bounds_string() );
    $self->remove_relation_to($other);
  }

  method RemoveAllRelations() {
    for ( $self->all_relations() )
    {
      $_->uninsert;
    }
  }

  method get_relation($other) {
    $self->get_relation_to($other);
  }

  method _get_other_end_of_reln($reln) {
    my ( $f, $s ) = $reln->get_ends();
    return $s if $f eq $self;
    return $f if $s eq $self;
    SErr->throw("relation error: not an end");
  }

  method recalculate_relations() {
    my %hash = %{ $self->relation_to };
    while ( my ( $k, $v ) = each %hash ) {
      my $type     = $v->get_type();
      my $new_type = $type->get_category()->FindTransformForCat( $v->get_ends );

      if ($new_type) {
        my ( $f, $s ) = $v->get_ends;
        my $new_rel =
        SRelation->new( { first => $f, second => $s, type => $new_type } );
        $v->uninsert;
        $new_rel->insert;
      }
      else {
        $v->uninsert;

        #main::message("A relation no longer valid, removing!");
      }
    }
  }

  method as_text() {
    my $structure_string = $self->get_structure_string();
    return "Seqsee::Object $structure_string";
  }

  multimethod CanBeSeenAs => ( '#', '#' ) => sub {
    my ( $a, $b ) = @_;
    return ResultOfCanBeSeenAs->newUnblemished() if $a == $b;
    return ResultOfCanBeSeenAs->NO();
  };

  multimethod CanBeSeenAs => ( 'Seqsee::Object', 'Seqsee::Object' ) => sub {
    my ( $obj, $structure ) = @_;
    return CanBeSeenAs( $obj, $structure->get_structure() );
  };

  multimethod CanBeSeenAs => ( 'Seqsee::Object', '#' ) => sub {
    my ( $object, $int ) = @_;
    my $lit_or_meto = $object->CanBeSeenAs_Literal0rMeto($int);
    ## lit_or_meto(elt): $lit_or_meto
    return $lit_or_meto if defined $lit_or_meto;
    return ResultOfCanBeSeenAs::NO();

  };

  multimethod CanBeSeenAs => ( 'Seqsee::Object', 'ARRAY' ) => sub {
    my ( $object, $structure ) = @_;
    my $meto_activeness = $object->get_metonym_activeness();
    my $metonym         = $object->get_metonym();
    my $starred         = $metonym ? $metonym->get_starred() :undef;
    ## before active meto
    if ($meto_activeness) {
      my $meto_seen_as =
      $object->CanBeSeenAs_Meto( $structure, $starred, $metonym );
      return $meto_seen_as if defined $meto_seen_as;
    }

    ## before by part
    my $part_seen_as = $object->CanBeSeenAs_ByPart($structure);
    return $part_seen_as if defined $part_seen_as;

    ## before meto
    if ($metonym) {
      my $meto_seen_as =
      $object->CanBeSeenAs_Meto( $structure, $starred, $metonym );
      return $meto_seen_as if defined $meto_seen_as;
    }
    ## failed CanBeSeenAs
    return ResultOfCanBeSeenAs::NO();
  };

  sub CanBeSeenAs_ByPart {
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

  sub CanBeSeenAs_Meto {
    scalar(@_) == 4 or confess;
    my ( $object, $structure, $starred, $metonym ) = @_;
    return ResultOfCanBeSeenAs->newEntireBlemish($metonym)
    if SUtil::compare_deep( $starred->get_structure(), $structure );
  }

  sub CanBeSeenAs_Literal {
    my ( $object, $structure ) = @_;
    return ResultOfCanBeSeenAs->newUnblemished()
    if SUtil::compare_deep( $object->get_structure(), $structure );
  }

  sub CanBeSeenAs_Literal0rMeto {
    my ( $object, $structure ) = @_;
    $structure = $structure->get_structure()
    if UNIVERSAL::isa( $structure, 'Seqsee::Object' );

    my $meto_activeness = $object->get_metonym_activeness();
    my $metonym         = $object->get_metonym();
    my $starred         = $metonym ? $metonym->get_starred() :undef;

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
  method GetEffectiveSlippages() {
    my @parts       = @{ $self->items };
    my $parts_count = scalar(@parts);
    my $return      = {};
    for my $idx ( 0 .. $parts_count - 1 ) {
      next unless $parts[$idx]->metonym_activeness;
      $return->{$idx} = $parts[$idx]->metonym;
    }
    return $return;
  }

  # XXX(Board-it-up): [2007/02/03] changing reln to ruleapp!
  method set_underlying_ruleapp($reln)
  {    # Was cumulative! Check that that i preserved.
    $reln or confess "Cannot set underlying relation to be an undefined value!";

    if ( UNIVERSAL::isa( $reln, "SRelation" )
      or UNIVERSAL::isa( $reln, 'Transform' ) )
    {
      $reln = SRule->create($reln) or return;
    }
    my $ruleapp;
    if ( UNIVERSAL::isa( $reln, "SRule" ) ) {
      $ruleapp = $reln->CheckApplicability(
        {
          objects   => [ @{ $self->items } ],
          direction => $DIR::RIGHT,
        }
      );    # could be undef.
    }
    else {
      confess "Funny argument $reln to set_underlying_ruleapp!";
    }

    $self->AddHistory("Underlying relation set: $ruleapp ");
    $self->underlying_relation($ruleapp);
  }

  method TellDirectedStory( $cat, $position_mode ) {
    my $bindings     = $self->GetBindingForCategory($cat);
    my $self_as_text = $self->as_text();
    confess "Object $self ($self_as_text) does not belong to category $cat!"
    unless $bindings;
    $bindings->TellDirectedStory( $self, $position_mode );
  }

};

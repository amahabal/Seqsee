use MooseX::Declare;
use MooseX::AttributeHelpers;

class Seqsee::Object {
  with 'Seqsee::Instance';
  with 'Seqsee::History';
  use English qw(-no_match_vars);
  use Class::Multimethods;

  multimethod 'FindMapping';
  multimethod 'ApplyMapping';

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


  sub get_group_p {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->group_p;
  }

  sub set_group_p {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $new_val) = @_;
    $self->group_p($new_val);
  }

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


  sub get_underlying_reln {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->underlying_relation
  }

  has relation_scheme => (
      is         => 'rw',
      isa        => 'Any',
  );
  

  sub get_reln_scheme {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->relation_scheme;
  }


  sub set_reln_scheme {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $new_scheme) = @_;
    $self->relation_scheme($new_scheme);
  }

  has metonym => (
    is  => 'rw',
    isa => 'Any',
  );


  sub get_metonym {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->metonym;
  }


  sub set_metonym {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $new_val) = @_;
    $self->metonym($new_val);
  }

  has is_metonym_of => (
    is  => 'rw',
    isa => 'Any',
  );


  sub get_is_a_metonym {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->is_metonym_of;
  }


  sub set_is_a_metonym {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $new_val) = @_;
    $self->is_metonym_of($new_val);
  }

  has metonym_activeness => (
    is  => 'rw',
    isa => 'Bool',
  );


  sub get_metonym_activeness {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->metonym_activeness;
  }


  sub set_metonym_activeness {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $new_val) = @_;
    $self->metonym_activeness($new_val);
  }

  has strength => (
    is  => 'rw',
    isa => 'Num',
  );


  sub get_strength {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->strength;
  }


  sub get_direction {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $DIR::RIGHT;
  }


  sub set_direction {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $dir) = @_;
    return if $dir eq $DIR::RIGHT;

    confess "Why am I setting a non-right direction?";
  }


  sub get_parts_ref {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
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


  sub annotate_with_cat {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
    my $bindings = $self->describe_as($cat);

    SErr::NotOfCat->throw() unless $bindings;
    return $bindings;
  }


  sub get_structure {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    [ map { $_->get_structure() } @{ $self->items } ];
  }


  sub get_flattened {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    [ map { @{ $_->get_flattened() } } @{ $self->items } ];
  }


  sub tell_forward_story {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
    my $bindings = $self->GetBindingForCategory($cat);
    confess "Object $self does not belong to category " . $cat->get_name()
    unless $bindings;
    $self->AddHistory( "Forward story telling for " . $cat->get_name );
    $bindings->tell_forward_story($self);
  }


  sub tell_backward_story {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
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


  sub get_subobj_given_range {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $range) = @_;
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


  sub get_at_position {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $position) = @_;
    my $range = $position->find_range($self);
    return $self->get_subobj_given_range($range);
  }


  sub apply_blemish_at {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ($self,  $meto_type, $position ) = @_;
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


  sub describe_as {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
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
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
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


  sub get_structure_string {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my $struct = $self->get_structure;
    SUtil::StructureToString($struct);
  }


  sub GetAnnotatedStructureString {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
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

  sub get_span {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return List::Util::sum( map { $_->get_span } @{ $self->items } );
  }


  sub apply_reln_scheme {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $scheme) = @_;
    return
    unless $scheme;
    if ( $scheme == RELN_SCHEME::CHAIN() ) {
      my $parts_ref = $self->get_parts_ref;
      my $cnt       = scalar(@$parts_ref);
      for my $i ( 0 .. ( $cnt - 2 ) ) {
        my ( $a, $b ) = ( $parts_ref->[$i], $parts_ref->[ $i + 1 ] );
        next if $a->get_relation($b);
        my $transform = FindMapping( $a, $b );
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


  sub recalculate_categories {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my $cats = $self->get_categories();
    for my $cat (@$cats) {
      $self->redescribe_as($cat);
    }
  }


  sub get_pure {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return SLTM::Platonic->create( $self->get_structure_string() );
  }


  sub HasAsItem {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $item) = @_;
    return $item ~~ $self->items;
  }

  sub Seqsee::Element::HasAsPartDeep {
    my ( $self, $item ) = @_;
    return $self eq $item;
  }


  sub HasAsPartDeep {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $item) = @_;
    for ( @{ $self->items } )
    {
      return 1 if $_ eq $item;
      return 1 if $_->HasAsPartDeep($item);
    }
    return 0;
  }


  sub SetMetonym {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $meto) = @_;
    my $starred = $meto->get_starred();
    SErr->throw("Metonym must be an Seqsee::Object! Got: $starred")
    unless UNIVERSAL::isa( $starred, "Seqsee::Object" );
    $starred->is_metonym_of($self);
    $self->metonym($meto);
  }


  sub SetMetonymActiveness {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $value) = @_;
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


  sub GetEffectiveObject {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return $self
    unless $self->metonym_activeness;
    return $self->metonym->get_starred();
  }


  sub GetEffectiveStructure {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return [
      map { $_->GetEffectiveObject()->get_structure } @{ $self->items }
    ];
  }

  sub Seqsee::Element::GetEffectiveStructure {
    my ($self) = @_;
    return $self->get_mag();
  }


  sub GetEffectiveStructureString {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return SUtil::StructureToString( $self->GetEffectiveStructure() );
  }


  sub GetUnstarred {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return $self->is_metonym_of() // $self;
  }


  sub AnnotateWithMetonym {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ($self,  $cat, $name ) = @_;
    my $is_of_cat = $self->is_of_category_p($cat);

    unless ($is_of_cat) {
      $self->annotate_with_cat($cat);
    }

    my $meto = $cat->find_metonym( $self, $name );
    SErr::MetonymNotAppicable->throw() unless $meto;

    $self->AddHistory( "Added metonym \"$name\" for cat " . $cat->get_name() );
    $self->SetMetonym($meto);
  }


  sub MaybeAnnotateWithMetonym {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ($self,  $cat, $name ) = @_;
    eval { $self->AnnotateWithMetonym( $cat, $name ) };

    if ( my $o = $EVAL_ERROR ) {
      confess $o unless ( UNIVERSAL::isa( $o, 'SErr::MetonymNotAppicable' ) );
    }
  }


  sub IsThisAMetonymedObject {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my $is_metonym_of = $self->is_metonym_of;
    return 0 if ( not($is_metonym_of) or $is_metonym_of eq $self );
    return 1;
  }


  sub ContainsAMetonym {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
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


  sub AddRelation {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $reln) = @_;
    my $other = $self->_get_other_end_of_reln($reln);

    if ( $self->has_relation_to($other) ) {
      SErr->throw("duplicate reln being added");
    }
    $self->AddHistory( "added reln to " . $other->get_bounds_string() );
    $self->set_relation_to( $other, $reln );
  }


  sub RemoveRelation {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $reln) = @_;
    my $other = $self->_get_other_end_of_reln($reln);
    $self->AddHistory( "removed reln to " . $other->get_bounds_string() );
    $self->remove_relation_to($other);
  }


  sub RemoveAllRelations {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    for ( $self->all_relations() )
    {
      $_->uninsert;
    }
  }


  sub get_relation {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $other) = @_;
    $self->get_relation_to($other);
  }


  sub _get_other_end_of_reln {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $reln) = @_;
    my ( $f, $s ) = $reln->get_ends();
    return $s if $f eq $self;
    return $f if $s eq $self;
    SErr->throw("relation error: not an end");
  }


  sub recalculate_relations {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my %hash = %{ $self->relation_to };
    while ( my ( $k, $v ) = each %hash ) {
      my $type     = $v->get_type();
      my $new_type = $type->get_category()->FindMappingForCat( $v->get_ends );

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


  sub as_text {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
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

  sub GetEffectiveSlippages {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
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

  sub set_underlying_ruleapp {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $reln) = @_;
    # Was cumulative! Check that that i preserved.
    $reln or confess "Cannot set underlying relation to be an undefined value!";

    if ( UNIVERSAL::isa( $reln, "SRelation" )
      or UNIVERSAL::isa( $reln, 'Mapping' ) )
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


  sub TellDirectedStory {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ($self,  $cat, $position_mode ) = @_;
    my $bindings     = $self->GetBindingForCategory($cat);
    my $self_as_text = $self->as_text();
    confess "Object $self ($self_as_text) does not belong to category $cat!"
    unless $bindings;
    $bindings->TellDirectedStory( $self, $position_mode );
  }

};

package Seqsee::Object;
  use overload(
    '~~' => sub { $_[0] eq $_[1] },
    '@{}'    => sub {  $_[0]->items },
    'bool'   => sub { $_[0] },
    fallback => 1,
  );
1;

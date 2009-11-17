use MooseX::Declare;
use Seqsee::Object;
use MooseX::AttributeHelpers;

class Seqsee::Anchored extends Seqsee::Object {
  use English qw(-no_match_vars);
  use Class::Multimethods;
  use List::Util qw(min max sum);

  has left_edge => (
    is  => 'rw',
    isa => 'Int',
  );
  has right_edge => (
    is  => 'rw',
    isa => 'Int',
  );

  sub get_left_edge {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->left_edge;
  }

  sub get_right_edge {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->right_edge;
  }
  has is_locked_against_deletion => (
    is  => 'rw',
    isa => 'Bool',
  );

  sub get_is_locked_against_deletion {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->is_locked_against_deletion;
  }

  sub set_is_locked_against_deletion {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ( $self, $new_val ) = @_;
    $self->is_locked_against_deletion($new_val);
  }

  method BUILD($opts_ref) {
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
  }

  sub recalculate_edges {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my %slots_taken;
    for my $item ( @{ $self->get_parts_ref } ) {
      confess "Seqsee::Anchored->create called with a non anchored object"
      unless UNIVERSAL::isa( $item, "Seqsee::Anchored" );
      my ( $left, $right ) = $item->get_edges();
      @slots_taken{ $left .. $right } = ( $left .. $right );
    }

    my @keys = values %slots_taken;
    ## @keys
    my ( $left, $right ) =
    List::MoreUtils::minmax( $keys[0], @keys )
    ; #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    $self->left_edge($left);
    $self->right_edge($right);
  }

  sub set_edges {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ( $self, $left, $right ) = @_;
    $self->left_edge($left);
    $self->right_edge($right);
    return $self;
  }

  sub get_edges {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return ( $self->left_edge, $self->right_edge );
  }

  sub create {
    my ( $package, @items ) = @_;
    SErr::EmptyCreate->throw() unless @items;
    if ( @items == 1 ) {
      return $items[0] if UNIVERSAL::isa( $items[0], 'Seqsee::Anchored' );
      confess "Unanchored object!";
    }

    SErr::HolesHere->throw('Holes here')
    if SWorkspace->are_there_holes_here(@items);

    # I assume @items are live.
    my $direction = SWorkspace::__FindObjectSetDirection(@items);
    return unless $direction->IsLeftOrRight();

    my $object = $package->new(
      {
        items      => [@items],
        group_p    => 1,
        left_edge  => -1,           # Will shortly be reset
        right_edge => -1,           # Will shortly be reset
        direction  => $direction,
      }
    );

    $object->recalculate_edges();
    $object->UpdateStrength();
    return $object;
  }

  # method: get_bounds_string
  # returns a string containing the left and right boundaries
  #

  sub get_bounds_string {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return q{ <} . $self->left_edge() . q{, } . $self->right_edge . q{> };
  }

  sub get_span {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return $self->right_edge() - $self->left_edge() + 1;
  }

  sub as_text {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self)           = @_;
    my $bounds_string    = $self->get_bounds_string();
    my $structure_string = $self->GetAnnotatedStructureString();
    my $ruleapp = $self->get_underlying_reln ? 'u' :'';
    return "Seqsee::Anchored $ruleapp$bounds_string $structure_string";
  }

  sub get_next_pos_in_dir {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ( $self, $direction ) = @_;
    if ( $direction eq DIR::RIGHT() ) {
      ## Dir Left
      return $self->right_edge() + 1;
    }
    elsif ( $direction eq DIR::LEFT() ) {
      ## Dir Left
      my $le = $self->left_edge();
      return unless $le > 0;
      return $le - 1;
    }
    else {
      confess "funny direction to extend in!!";
    }
  }

  sub spans {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ( $self, $other ) = @_;
    my ( $sl,   $sr )    = $self->get_edges;
    my ( $ol,   $or )    = $other->get_edges;
    return ( $sl <= $ol and $or <= $sr );
  }

  sub overlaps {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ( $self, $other ) = @_;
    my ( $sl,   $sr )    = $self->get_edges;
    my ( $ol,   $or )    = $other->get_edges;
    return ( ( $sr <= $or and $sr >= $ol ) or ( $or <= $sr and $or >= $sl ) );
  }

  sub UpdateStrength {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my $strength_from_parts = 20 + 0.2 *
    ( sum( map { $_->get_strength() } @{ $self->get_parts_ref() } ) || 0 );
    my $strength_from_categories = 30 * (
      sum(
        @{ SLTM::GetRealActivationsForConcepts( $self->get_categories() ) }
      )
      || 0
    );
    my $strength = $strength_from_parts + $strength_from_categories;
    $strength += $Global::GroupStrengthByConsistency{$self};
    $strength = 100 if $strength > 100;
    ### p, c, t: $strength_from_parts, $strength_from_categories, $strength
    $self->strength($strength);
  }

  sub Extend {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ( $self, $to_insert, $insert_at_end_p ) = @_;
    my $parts_ref = $self->get_parts_ref();

    my @parts_of_new_group;
    if ($insert_at_end_p) {
      @parts_of_new_group = ( @$parts_ref, $to_insert );
    }
    else {
      @parts_of_new_group = ( $to_insert, @$parts_ref );
    }

    my $potential_new_group = Seqsee::Anchored->create(@parts_of_new_group)
    or SErr::CouldNotCreateExtendedGroup->new("Extended group creation failed")
    ->throw();
    my $conflicts =
    SWorkspace::__FindGroupsConflictingWith($potential_new_group);
    if ($conflicts) {
      $conflicts->Resolve( { IgnoreConflictWith => $self } ) or return;
    }

    # If there are supergroups, they must die. Kludge, for now:
    if ( my @supergps = SWorkspace->GetSuperGroups($self) ) {
      if ( SUtil::toss(0.5) ) {
        for (@supergps) {
          SWorkspace::__DeleteGroup($_);
        }
      }
      else {
        return;
      }
    }

    # If we get here, all conflicting incumbents are dead.
    @$parts_ref = @parts_of_new_group;

    $self->Update();
    $self->AddHistory( "Extended to become " . $self->get_bounds_string() );
    return 1;
  }

  sub Update {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->recalculate_edges();
    $self->recalculate_categories();
    $self->recalculate_relations();
    $self->UpdateStrength();
    if ( my $underlying_reln = $self->underlying_relation() ) {
      eval { $self->set_underlying_ruleapp( $underlying_reln->get_rule() ) };
      if ($EVAL_ERROR) {
        SWorkspace->remove_gp($self);
        return;
      }
      confess "underlying_reln lost here" unless $self->get_underlying_reln;
    }

    # SWorkspace::UpdateGroupsContaining($self);
    SWorkspace::__UpdateGroup($self);
  }

  sub FindExtension {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ( $self, $direction_to_extend_in, $skip ) = @_;
    my $underlying_ruleapp = $self->get_underlying_reln()
    or return;
    return $underlying_ruleapp->FindExtension(
      {
        direction_to_extend_in  => $direction_to_extend_in,
        skip_this_many_elements => $skip
      }
    );
  }

  sub CheckSquintability {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ( $self, $intended ) = @_;
    my $intended_structure_string = $intended->get_structure_string();
    return map {
      $self->CheckSquintabilityForCategory( $intended_structure_string, $_ )
    } @{ $self->get_categories() };
  }

  sub CheckSquintabilityForCategory {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ( $self, $intended_structure_string, $category ) = @_;

    if ( my $squintability_checker = $category->get_squintability_checker() ) {
      return $squintability_checker->( $self, $intended_structure_string );
    }

    my $bindings = $self->GetBindingForCategory($category)
    or confess
    "CheckSquintabilityForCategory called on object not an instance of the category";

    my @meto_types = $category->get_meto_types();
    my @return;
    for my $name (@meto_types) {
      my $finder = $category->get_meto_finder($name);
      my $squinted = $finder->( $self, $category, $name, $bindings )
      or next;
      next
      unless $squinted->get_starred()->get_structure_string() eq
        $intended_structure_string;
      push @return, $squinted->get_type();
    }
    return @return;
  }

  sub IsFlushRight {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->right_edge == $SWorkspace::ElementCount - 1;
  }

  sub IsFlushLeft {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->left_edge == 0;
  }

}

package Seqsee::Anchored;
use overload(
  '~~' => sub { $_[0] eq $_[1] },
  '@{}'    => sub { $_[0]->items },
  'bool'   => sub { $_[0] },
  fallback => 1,
);

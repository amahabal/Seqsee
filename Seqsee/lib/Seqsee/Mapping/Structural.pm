use 5.10.1;
use MooseX::Declare;
use MooseX::AttributeHelpers;
class Seqsee::Mapping::Structural extends Seqsee::Mapping {
  use Memoize;

  has category => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_category() {
    $self->category;
  }

  method set_category($new_val) {
    $self->category($new_val);
  }

  has meto_mode => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_meto_mode() {
    $self->meto_mode;
  }

  method set_meto_mode($new_val) {
    $self->meto_mode($new_val);
  }

  # ASSUMPTION: pos_mode_of is always forward.

  has position_relation => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_position_reln() {
    $self->position_relation;
  }

  method set_position_reln($new_val) {
    $self->position_relation($new_val);
  }

  has metonymy_relation => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_metonymy_reln() {
    $self->metonymy_relation;
  }

  method set_metonymy_reln($new_val) {
    $self->metonymy_relation($new_val);
  }

  has direction_relation => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_direction_reln() {
    $self->direction_relation;
  }

  method set_direction_reln($new_val) {
    $self->direction_relation($new_val);
  }

  has slippages => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[Any]',
    default   => sub { {} },
    provides  => {
      'get'    => 'get_slippage',
      'set'    => 'set_slippage',
      'exists' => 'has_slippage',
      'delete' => 'remove_slippage',
    }
  );

  method get_slippages() {
    $self->slippages;
  }

  method set_slippages($new_val) {
    $self->slippages($new_val);
  }

  has changed_bindings => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[Any]',
    default   => sub { {} },
    provides  => {
      'get'    => 'get_changed_binding',
      'set'    => 'set_changed_binding',
      'exists' => 'has_changed_binding',
      'delete' => 'remove_changed_binding',
    }
  );

  method get_changed_bindings() {
    $self->changed_bindings;
  }

  method set_changed_bindings($new_val) {
    $self->changed_bindings($new_val);
  }

  sub create {
    my ( $package, $opts_ref ) = @_;
    my $meto_mode = $opts_ref->{meto_mode} or confess "need meto_mode";
    if ( not $meto_mode->is_metonymy_present() ) {
      $opts_ref->{metonymy_reln} = 'x';
    }
    if ( not $meto_mode->is_position_relevant() ) {
      $opts_ref->{position_reln} = 'x';
    }

    my $string = join(
      '#',
      (
        map { $opts_ref->{$_} }
        qw(category meto_mode metonymy_reln position_reln direction_reln)
      ),
      join( ';',
        SUtil::hash_sorted_as_array( %{ $opts_ref->{changed_bindings} } ) ),
      join( ';', SUtil::hash_sorted_as_array( %{ $opts_ref->{slippages} } ) ),
    );
    state %MEMO;
    return $MEMO{$string} ||= $package->new($opts_ref);
  }

  method FlippedVersion() {
    my $new_slippages = _FlipSlippages( $self->slippages() ) // return;
    my $new_bindings_change =
    _FlipChangedBindings( $self->changed_bindings(), $self->slippages() )
    // return;

    ## new_slippages: $new_slippages
    ## new_bindings_change: $new_bindings_change

    my $new_position_reln = $self->position_relation()->FlippedVersion()
    if ref( $self->position_relation() );
    my $new_metonymy_reln = $self->metonymy_relation()->FlippedVersion()
    if ref( $self->metonymy_relation() );
    my $new_direction_reln = $self->direction_relation()->FlippedVersion()
    if ref( $self->direction_relation() );

    my $flipped = Seqsee::Mapping::Structural->create(
      {
        category         => $self->category(),
        meto_mode        => $self->meto_mode(),
        position_reln    => $new_position_reln,
        metonymy_reln    => $new_metonymy_reln,
        direction_reln   => $new_direction_reln,
        changed_bindings => $new_bindings_change,
        slippages        => $new_slippages,
      }
    );
    $flipped->CheckSanity()
    or
    main::message( "Flip problematic!" . join( ';', %$new_bindings_change ) );
    return $flipped;
  }

  memoize('FlippedVersion');

  sub _FlipChangedBindings {
    my ( $old_bindings, $slippages ) = @_;
    my %new_bindings;
    my %old_bindings = %$old_bindings;
    while ( my ( $k, $v ) = each %old_bindings ) {
      my $new_v = $v->FlippedVersion() // return;
      my $new_k;
      if ( exists $slippages->{$k} ) {
        $new_k = $slippages->{$k};
      }
      else {
        $new_k = $k;
      }
      $new_bindings{$new_k} = $new_v;
    }
    return \%new_bindings;
  }

  sub _FlipSlippages {
    my ($old_slippages) = @_;
    my %new_slippages;
    my %keys_seen;
    my %old_slippages = %$old_slippages;
    while ( my ( $k, $v ) = each %old_slippages ) {
      return if $keys_seen{$v}++;
      $new_slippages{$v} = $k;
    }
    return \%new_slippages;
  }

  sub get_pure {
    return $_[0];
  }

  method IsEffectivelyASamenessRelation() {
    my $id = ident $self;
    while ( my ( $k, $v ) = each %{ $self->slippages() } ) {
      return unless $k eq $v;
    }
    while ( my ( $k, $v ) = each %{ $self->changed_bindings_of() } ) {
      return unless $v->IsEffectivelyASamenessRelation();
    }
    if ( $self->meto_mode()->is_metonymy_present() ) {
      return
      unless $self->metonymy_relation()->IsEffectivelyASamenessRelation();
      return
      unless $self->direction_relation()->IsEffectivelyASamenessRelation();
      if ( $self->meto_mode()->is_position_relevant() ) {
        return
        unless $self->position_relation()->IsEffectivelyASamenessRelation();
      }
    }

    return 1;
  }

  method get_memory_dependencies() {
    return grep { ref($_) } (
      $self->category(),           $self->meto_mode(),
      $self->position_relation(),  $self->metonymy_relation(),
      $self->direction_relation(), values %{ $self->changed_bindings() }
    );
  }

  method as_text() {
    my $cat_name         = $self->category()->get_name();
    my $changed_bindings = $self->changed_bindings();
    my $changed_bindings_string;
    my $metonymy_presence = $self->meto_mode()->is_metonymy_present() ? '*' :'';
    my %slippages = %{ $self->slippages() };
    if (%slippages) {

      while ( my ( $new, $old ) = each %slippages ) {
        my $reln_for_this_attribute = $changed_bindings->{$new};
        if ($reln_for_this_attribute) {
          $changed_bindings_string .=
          "($new => " . $reln_for_this_attribute->as_text();
          $changed_bindings_string .= " (of $old)";
          $changed_bindings_string .= ');';
        }
        else {
          if ( $old ne $new ) {
            $changed_bindings_string .= "new $new is the earlier $old;";
          }
        }
      }
    }
    else {
      while ( my ( $k, $v ) = each %$changed_bindings ) {
        $changed_bindings_string .= "$k => " . $v->as_text() . ";";
      }
    }
    chop($changed_bindings_string);
    return "[$cat_name$metonymy_presence] $changed_bindings_string";
  }

  method serialize() {
    return SLTM::encode(
      $self->category(),          $self->meto_mode(),
      $self->metonymy_relation(), $self->direction_relation(),
      $self->position_relation(), $self->changed_bindings(),
      $self->slippages()
    );
  }

  sub deserialize {
    my ( $package, $string ) = @_;
    my %opts;
    @opts{
      qw{category meto_mode metonymy_reln direction_reln position_reln changed_bindings slippages}
    } = SLTM::decode($string);
    $package->create( \%opts );
  }

  method get_complexity() {
    my $complexity_of_category;
    given ( $self->category() ) {
      when ( [ $S::ASCENDING, $S::DESCENDING, $S::SAMENESS ] ) {
        $complexity_of_category = 0.1
      }
      when ( $_->isa('SCat::OfObj::Interlaced') ) {
        $complexity_of_category = 0.1 * $_->get_parts_count();
      }
      default { $complexity_of_category = 0.3; }
    }

    my $total_complexity = $complexity_of_category;
    given ( $self->meto_mode() ) {
      when ($METO_MODE::NONE) { }
      default { $total_complexity += 0.2; }
    }

    for ( values %{ $self->changed_bindings() } ) {
      $total_complexity += $_->get_complexity();
    }

    my %slippages = %{ $self->slippages() };
    while ( my ( $k, $v ) = each %slippages ) {
      $total_complexity += 0.2 unless $k eq $v;
    }

    $total_complexity = 0.9 if $total_complexity > 0.9;
    return $total_complexity;
  };
};
1;

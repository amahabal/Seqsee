use MooseX::Declare;
use MooseX::AttributeHelper;
class Mapping::Numeric extends Mapping {
  use Memoize;

  has name => (
    is  => 'rw',
    isa => 'Str'
  );

  method get_name() {
    $self->name;
  }

  method set_name($new_val) {
    $self->name($new_val);
  }

  has category => (
    is  => 'rw',
    isa => 'Str'
  );

  method get_category() {
    $self->category;
  }

  method set_category($new_val) {
    $self->category($new_val);
  }

  sub create {
    my ( $package, $name, $category ) = @_;
    die "Mapping::Numeric creation attempted without name!" unless $name;
    state %MEMO;
    return $MEMO{ SLTM::encode( $name, $category ) } //= $package->new(
      {
        name     => $name,
        category => $category,
      }
    );
  }

  method serialize() {
    return SLTM::encode( $self->name(), $self->category() );
  }

  sub deserialize {
    my ( $package, $str ) = @_;
    $package->create( SLTM::decode($str) );
  }

  method get_memory_dependencies() {
    return $self->category();
  }

  sub get_pure {
    return $_[0];
  }

  method FlippedVersion() {
    state $FlipName =
    {qw{same same pred succ succ pred flip flip no_flip no_flip}};
    return Mapping::Numeric->create( $FlipName->{ $self->name() },
      $self->category() );
  }

  method IsEffectivelyASamenessRelation() {
    return $self->name() eq 'same' ? 1 :0;
  }

  method as_text() {
    my $cat = $self->category();
    my $cat_string = ( $cat eq $S::NUMBER ) ? '' :$cat->as_text() . ' ';
    return "$cat_string$self->name()";
  } memoize('as_text');

  method GetRelationBasedCategory() {
    return SCat::OfObj::RelationTypeBased->Create($self)
    unless $self->category() eq $S::NUMBER;

    my $name = $self->name();
    given ($name) {
      when ('succ') { return $S::ASCENDING; }
      when ('same') { return $S::SAMENESS; }
      when ('pred') { return $S::DESCENDING; }
      default       { confess "Should not reach herre" }
    }
  }

  method get_complexity() {
    my $category = $self->category();
    my $name     = $self->name();

    if ( $category eq $S::NUMBER ) {
      return 0 if $name eq 'same';
      return 0.1;
    }

    return 0.7 if $category->isa('SCat::OfObj::Alternating');
    return 0.4;
  }

  memoize('get_complexity');
}
1;

package SCat::Odd;
## BASE MODULES FOR ALL FILES
use 5.10.0;
use strict;
use warnings;
use Carp;
use Smart::Comments '###';

use Class::Std;
our $Odd;

my $builder = sub {
  my ( $self, $args_ref ) = @_;
  confess q{need mag} unless exists( $args_ref->{mag} );
  my $ret = SElement->create( $args_ref->{mag}, -1 );
  $ret->add_category( $self, SBindings->create( {}, {}, $ret ) );

  return $ret;
};

my $instancer = sub {
  my ( $cat, $object ) = @_;
  return unless $object->isa('SElement');
  my $mag = $object->get_mag();
  return unless $mag % 2;
  return SBindings->create( {}, {}, $object );
};

my $relation_finder = sub {
  my ( $cat, $e1, $e2 ) = @_;
  *__ANON__ = "((__ANON__ Odd-specific relation_finder))";
  my ( $m1, $m2 ) =
  ( ( ref $e1 ? $e1->get_mag() :$e1 ), ( ref $e2 ? $e2->get_mag() :$e2 ) );
  my $text;
  if    ( $m2 == $m1 )     { $text = 'same'; }
  elsif ( $m2 == $m1 + 2 ) { $text = 'succ'; }
  elsif ( $m2 == $m1 - 2 ) { $text = 'pred'; }
  else {
    say "Could not connect $m1 and $m2";
    return;
  }
  return SReln::Simple->new(
    {
      first    => $e1,
      second   => $e2,
      text     => $text,
      category => $Odd
    }
  );
};

my $FindTransformForCat = sub {
  my ( $me, $a, $b ) = @_;

  # Assume $a, $b are integers.

  my $str;
  if ( $a == $b ) {
    $str = "same";
  }
  elsif ( $a + 2 == $b ) {
    $str = "succ";
  }
  elsif ( $a - 2 == $b ) {
    $str = "pred";
  }
  else {
    return;
  }
  return Transform::Numeric->create( $str, $me );
};

my $relation_applier = sub {
  my ( $cat, $relation_type, $original_object ) = @_;
  my $text = $relation_type->get_text() // return;
  my $mag =
  ref($original_object) ? $original_object->get_mag() :$original_object;
  my $new_mag;

  given ($text) {
    when ('same') { $new_mag = $mag }
    when ('succ') { $new_mag = $mag + 2 }
    when ('pred') { $new_mag = $mag - 2 }
  }

  $new_mag // return;
  return ref($original_object) ? $cat->build( { mag => $new_mag } ) :$new_mag;

};

my $ApplyTransformForCat = sub {
  my ( $cat, $transform, $object ) = @_;

  # Assume $object is number..

  my $name = $transform->get_name();
  my $mag  = $object;
  my $new_mag;
  given ($name) {
    when ('same') { $new_mag = $mag }
    when ('succ') { $new_mag = $mag + 2 }
    when ('pred') { $new_mag = $mag - 2 }
  }
  $new_mag // return;
  return $new_mag;
};

$Odd = SCat::OfObj::Numeric->new(
  {
    name               => 'Odd',
    to_recreate        => '$S::ODD',
    builder            => $builder,
    instancer          => $instancer,
    metonymy_finders   => {},
    metonymy_unfinders => {},
    relation_finder    => $relation_finder,
    relation_applier   => $relation_applier,
    find_transform     => $FindTransformForCat,
    apply_transform    => $ApplyTransformForCat,
  }
);

1;

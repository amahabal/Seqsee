#####################################################
#
#    Package: SCat::Number
#
#####################################################
#####################################################

package SCat::Number;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use Smart::Comments;
multimethod 'find_relation_string';

my $builder = sub {
  my ( $self, $args_ref ) = @_;
  confess q{need mag} unless exists( $args_ref->{mag} );
  my $ret = SElement->create( $args_ref->{mag}, -1 );
  $ret->add_category( $self, SBindings->create( {}, $args_ref, $ret ) );

  return $ret;
};

my $instancer = sub {
  my ( $cat, $object ) = @_;
  return unless $object->isa('SElement');
  return SBindings->create( {}, { mag => $object->get_mag() }, $object );
};

my $meto_finder_square = sub {
  my ( $object, $cat, $name, $bindings ) = @_;
  my $mag      = $bindings->GetBindingForAttribute('mag');
  my $mag_sqrt = sqrt($mag);
  return unless int($mag_sqrt) == $mag_sqrt;
  my $starred = SElement->create( $mag_sqrt, -1 );
  return SMetonym->new(
    {
      category  => $cat,
      name      => $name,
      starred   => $starred,
      unstarred => $object,
      info_loss => {},
      info_gain => {},
    }
  );
};

my $meto_unfinder_square = sub {
  my ( $cat, $name, $info_loss, $object ) = @_;
  my $mag = $object->get_mag();
  return $cat->build( { mag => $mag * $mag } );
};

my $relation_finder = sub {
  my ( $self, $e1, $e2 ) = @_;
  *__ANON__ = "((__ANON__ Number-specific relation_finder))";
  my $relation_string = find_relation_string( ( ref $e1 ? $e1->get_mag() :$e1 ),
    ( ref $e2 ? $e2->get_mag() :$e2 ) );
  ### relation_string: $relation_string
  if ($relation_string) {
    return SReln::Simple->new(
      {
        text   => $relation_string,
        first  => $e1,
        second => $e2
      }
    );
  }
  return;
};

my $FindTransformForCat = sub {
  my ( $me, $a, $b ) = @_;
  *__ANON__ = "(__ANON__ FindTransformForCat for Number)";

  # Assume $a, $b are integers.

  my $str;
  if ( $a == $b ) {
    $str = "same";
  }
  elsif ( $a + 1 == $b ) {
    $str = "succ";
  }
  elsif ( $a - 1 == $b ) {
    $str = "pred";
  }
  else {
    return;
  }
  return Transform::Numeric->create( $str, $me );
};

my $ApplyTransformForCat = sub {
  my ( $me, $transform, $number ) = @_;
  *__ANON__ = "(__ANON__ ApplyTransformForCat for Number)";
  given ( $transform->get_name() ) {
    when ('same') { return $number }
    when ('succ') { return $number + 1 }
    when ('pred') { return $number - 1 }
  }
};

our $Number = SCat::OfObj::Numeric->new(
  {
    name               => 'number',
    to_recreate        => '$S::NUMBER',
    builder            => $builder,
    instancer          => $instancer,
    metonymy_finders   => {},                # square => $meto_finder_square},
    metonymy_unfinders => {},                # square => $meto_unfinder_square},
    relation_finder    => $relation_finder,
    find_transform  => $FindTransformForCat,
    apply_transform => $ApplyTransformForCat,
  }
);

1;


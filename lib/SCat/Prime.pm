package SCat::Prime;
use 5.10.0;
use strict;
use Class::Std;
use Carp;

our $Prime;
my @Primes = qw{2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59
61 67 71 73 79 83 89 97};
my %Primes = map { $_ => 1 } @Primes;
my $LargestPrime = List::Util::max(@Primes);

sub IsPrime {
  my ($num) = @_;
  my $reply = $num ~~ %Primes ? 1 :0;

  # say "IsPrime called on >>$num<< ==> $reply";
  return $reply;
}

sub NextPrime {
  my ($num) = @_;
  return if $num >= $LargestPrime;
  $num++;

  while ( not( $num ~~ %Primes ) ) { $num++ }
  return $num;
}

sub PreviousPrime {
  my ($num) = @_;
  return if $num <= 2;
  $num--;

  while ( not( $num ~~ %Primes ) ) { $num-- }
  return $num;
}

# To build: need magnitude.
my $builder = sub {
  my ( $self, $args_ref ) = @_;
  confess q{need mag} unless exists( $args_ref->{mag} );
  my $ret = SElement->create( $args_ref->{mag}, -1 );
  $ret->add_category( $self, SBindings->create( {}, {}, $ret ) );

  return $ret;
};

# To check if instance:
my $instancer = sub {
  my ( $cat, $object ) = @_;
  return unless $object->isa('SElement');
  my $mag = $object->get_mag();
  return unless IsPrime($mag);
  return SBindings->create( {}, {}, $object );
};

my $relation_finder = sub {
  my ( $cat, $e1, $e2 ) = @_;
  *__ANON__ = "((__ANON__ Prime-specific relation_finder))";
  my ( $m1, $m2 ) =
  ( ( ref $e1 ? $e1->get_mag() :$e1 ), ( ref $e2 ? $e2->get_mag() :$e2 ) );
  my $text;
  say "$m1 and $m2: ", NextPrime($m1), ' and ', PreviousPrime($m1);
  if    ( $m2 == $m1 )                { $text = 'same'; }
  elsif ( $m2 == NextPrime($m1) )     { $text = 'succ'; }
  elsif ( $m2 == PreviousPrime($m1) ) { $text = 'pred'; }
  else {
    say "Could not connect $m1 and $m2";
    return;
  }
  return SReln::Simple->new(
    {
      first    => $e1,
      second   => $e2,
      text     => $text,
      category => $Prime
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
  elsif ( NextPrime($a) == $b ) {
    $str = "succ";
  }
  elsif ( PreviousPrime($a) == $b ) {
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
    when ('succ') { $new_mag = NextPrime($mag) }
    when ('pred') { $new_mag = PreviousPrime($mag) }
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
    when ('succ') { $new_mag = NextPrime($mag) }
    when ('pred') { $new_mag = PreviousPrime($mag) }
  }
  $new_mag // return;
  return $new_mag;
};

$Prime = SCat::OfObj::Numeric->new(
  {
    name               => 'Prime',
    to_recreate        => '$S::PRIME',
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

package Transform::Position;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};

my %text_of : ATTR(:name<text>);

sub create {
  my ( $package, $text ) = @_;
  state %MEMO;
  return $MEMO{$text} ||= $package->new( { text => $text } );
}

my $Successor   = Transform::Position->create('succ');
my $Predecessor = Transform::Position->create('pred');
my $SamePos     = Transform::Position->create('same');
my %ComplexityLookup =
( $Successor => 0.9, $Predecessor => 0.9, $SamePos => 1 );

sub get_memory_dependencies { return; }

sub serialize {
  my ($self) = @_;
  return $text_of{ ident $self};
}

sub deserialize {
  my ( $package, $str ) = @_;
  $package->create($str);
}

my $relation_finder = sub {
  my ( $p1, $p2 ) = @_;
  my $index1 = $p1->get_index();
  my $index2 = $p2->get_index();
  my $diff   = $index2 - $index1;
   $diff == 1  ? return $Successor
  :$diff == -1 ? return $Predecessor
  :$diff == 0  ? return $SamePos
  :              return;
};

sub as_text {
  my ($self) = @_;
  return "Transform::Position " . $text_of{ ident $self};
}

multimethod FindTransform => qw(SPos::Forward SPos::Forward) =>
$relation_finder;
multimethod FindTransform => qw(SPos::Backward SPos::Backward) =>
$relation_finder;
multimethod FindTransform => qw(SPos SPos) => sub {
  return;
};

multimethod ApplyTransform => qw(Transform::Position SPos::Forward) => sub {
  my ( $rel, $pos ) = @_;
  my $index = $pos->get_index();
   ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Forward' ) )
  :( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Forward' ) )
  :( $rel eq $SamePos )     ? return $pos
  :                           return;
};

multimethod ApplyTransform => qw(Transform::Position SPos::Backward) => sub {
  my ( $rel, $pos ) = @_;
  my $index = $pos->get_index();
   ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Backward' ) )
  :( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Backward' ) )
  :( $rel eq $SamePos )     ? return $pos
  :                           return;
};

sub get_pure {
  return $_[0];
}

sub IsEffectivelyASamenessRelation {
  my ($self) = @_;
  return $self eq $SamePos ? 1 :0;
}

sub FlippedVersion {
  my ($self) = @_;
  my $id = ident $self;
  state $FlipName = {qw{same same pred succ succ pred }};
  return Transform::Position->create( $FlipName->{ $text_of{$id} } );
}

1;


use 5.10.1;
use MooseX::Declare;
use MooseX::AttributeHelpers;
class Seqsee::Mapping::Position {
  use Class::Multimethods;
  has text => (
    is  => 'rw',
    isa => 'Str'
  );

  method get_text() {
    $self->text;
  }

  method set_text($new_val) {
    $self->text($new_val);
  }

  sub create {
    my ( $package, $text ) = @_;
    state %MEMO;
    return $MEMO{$text} ||= $package->new( { text => $text } );
  }

  our $Successor   = Seqsee::Mapping::Position->create('succ');
  our $Predecessor = Seqsee::Mapping::Position->create('pred');
  our $SamePos     = Seqsee::Mapping::Position->create('same');
  our %ComplexityLookup =
  ( $Successor => 0.9, $Predecessor => 0.9, $SamePos => 1 );

  sub get_memory_dependencies { return; }

  method serialize() {
    return $self->text();
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

  method as_text() {
    return "Seqsee::Mapping::Position " . $self->text();
  }

  multimethod FindTransform => qw(SPos::Forward SPos::Forward) =>
  $relation_finder;
  multimethod FindTransform => qw(SPos::Backward SPos::Backward) =>
  $relation_finder;
  multimethod FindTransform => qw(SPos SPos) => sub {
    return;
  };

  multimethod ApplyTransform => qw(Seqsee::Mapping::Position SPos::Forward) => sub {
    my ( $rel, $pos ) = @_;
    my $index = $pos->get_index();
     ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Forward' ) )
    :( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Forward' ) )
    :( $rel eq $SamePos )     ? return $pos
    :                           return;
  };

  multimethod ApplyTransform => qw(Seqsee::Mapping::Position SPos::Backward) => sub {
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

  method IsEffectivelyASamenessRelation() {
    return $self eq $SamePos ? 1 :0;
  }

  method FlippedVersion() {
    state $FlipName = {qw{same same pred succ succ pred }};
    return Mapping::Position->create( $FlipName->{ $self->text() } );
  }
}
1;


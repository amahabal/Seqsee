use MooseX::Declare;
class Seqsee::Element extends Seqsee::Anchored {
  use overload(
    '~~' => sub { $_[0] eq $_[1] },
    '@{}'    => sub { $_[0]->items },
    'bool'   => sub { 1 },
    fallback => 1,
  );

  has magnitude => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
  );

  method get_mag() { $self->magnitude }

  method BUILD($opts_ref) {
    my $magnitude = $self->magnitude;
    $self->describe_as($S::NUMBER);
    $self->describe_as($S::PRIME)
    if ( $Global::Feature{Primes}
      and SCat::Prime::IsPrime($magnitude) );
    if ( $Global::Feature{Parity} ) {
      if ( $magnitude % 2 ) {
        $self->describe_as($S::ODD);
      }
      else {
        $self->describe_as($S::EVEN);
      }
    }
  }

  # method: create
  # Use this: passes the right argumets along to the constructor
  #
  sub create {
    my ( $package, $mag, $pos ) = @_;
    my $obj = $package->new(
      {
        group_p    => 0,
        magnitude  => $mag,
        left_edge  => $pos,
        right_edge => $pos,
        strength   => 20,     # default strength for elements
      }
    );
    $obj->_insert_items($obj);
    return $obj;
  }

  method get_structure() {
    $self->magnitude;
  }

  method as_text() {
    my ( $l, $r ) = $self->get_edges;
    my $mag = $self->magnitude;
    return join( "", ( ref $self ), ":[$l,$r] $mag" );
  }

  our $POS_FIRST = SPos->new(1);
  our $POS_LAST  = SPos->new(-1);

  method get_at_position($position) {
    return $self
    if ( $position eq $POS_FIRST or $position eq $POS_LAST );
    SErr::Pos::OutOfRange->throw("out of range for SElement");
  }

  method get_flattened() {
    [ $self->magnitude ];
  }

  method UpdateStrength() {

  }

  method CheckSquintability($intended) {
    $self->describe_as($S::NUMBER);
    return Seqsee::Anchored::CheckSquintability( $self, $intended );
  }

}

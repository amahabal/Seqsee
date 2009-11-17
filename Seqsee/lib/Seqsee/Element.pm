use MooseX::Declare;
use MooseX::AttributeHelpers;
class Seqsee::Element extends Seqsee::Anchored {

  has magnitude => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
  );


  sub get_mag {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->magnitude;
  }

  sub BUILD {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $opts_ref) = @_;
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


  sub get_structure {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->magnitude;
  }


  sub as_text {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    my ( $l, $r ) = $self->get_edges;
    my $mag = $self->magnitude;
    return join( "", ( ref $self ), ":[$l,$r] $mag" );
  }

  our $POS_FIRST = SPos->new(1);
  our $POS_LAST  = SPos->new(-1);


  sub get_at_position {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $position) = @_;
    return $self
    if ( $position eq $POS_FIRST or $position eq $POS_LAST );
    SErr::Pos::OutOfRange->throw("out of range for SElement");
  }


  sub get_flattened {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    [ $self->magnitude ];
  }


  sub UpdateStrength {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;

  }


  sub CheckSquintability {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $intended) = @_;
    $self->describe_as($S::NUMBER);
    return Seqsee::Anchored::CheckSquintability( $self, $intended );
  }

};

package Seqsee::Element;
use overload (
  '~~' => sub { $_[0] eq $_[1] },
  '@{}' => sub {
    [ $_[0] ]
  },
  'bool'   => sub { $_[0] },
  fallback => 1
);

1;


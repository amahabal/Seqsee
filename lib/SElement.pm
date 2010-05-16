#####################################################
#
#    Package: SElement
#
#####################################################
#   Manages elements
#
#   Don't know how this fits in exactly. But the workspace, instead of having raw integers (or SObjects) will have SElements. When they are composed into objects, I may just use their integer core. Hmmmm...
#####################################################

package SElement;
use strict;
use Carp;
use Class::Std;
use base qw{SAnchored};
use overload fallback => 1;

my %mag_of : ATTR(:get<mag>);

sub BUILD {
  my ( $self, $id, $opts ) = @_;
  confess "Need mag" unless defined $opts->{mag};
  $mag_of{$id} = int( $opts->{mag} );
  $self->describe_as($S::NUMBER);
  $self->describe_as($S::PRIME)
  if ( $Global::Feature{Primes} and SCategory::Prime::IsPrime( $opts->{mag} ) );
  if ( $Global::Feature{Parity} ) {
    if ( $opts->{mag} % 2 ) {
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
      items      => [$mag],
      group_p    => 0,
      mag        => $mag,
      left_edge  => $pos,
      right_edge => $pos,
      strength   => 20,       # default strength for elements
    }
  );
  $obj->get_parts_ref()->[0] = $obj;    #[sic]
  return $obj;
}

# method: get_structure
# just returns the magnitude
#
sub get_structure {
  my ($self) = @_;
  return $mag_of{ ident $self};
}

sub as_text {
  my ($self) = @_;
  my ( $l, $r ) = $self->get_edges;
  my $mag = $self->get_mag;
  return join( "", ( ref $self ), ":[$l,$r] $mag" );
}

my $POS_FIRST = SPos->new(1);
my $POS_LAST  = SPos->new(-1);

sub get_at_position {
  my ( $self, $position ) = @_;
  return $self if ( $position eq $POS_FIRST or $position eq $POS_LAST );
  SErr::Pos::OutOfRange->throw("out of range for SElement");
}

sub get_flattened {
  my ($self) = @_;
  return [ $self->get_mag ];
}

sub UpdateStrength {

  # do nothing.
}

sub CheckSquintability {
  my ( $self, $intended ) = @_;
  $self->describe_as($S::NUMBER);
  return SAnchored::CheckSquintability( $self, $intended );
}

1;

package SInt;
use Class::Std;

use SInstance;
our @ISA = qw{SInstance};

my %mag :ATTR( :get<mag>);

sub BUILD {
  $mag{ $_[1] } = $_[2]->{mag};
}
sub flatten{
  $mag{ident shift};
}

sub clone{
  my $self = shift;
  return SInt->new({mag => $mag{ ident $self }});
}

sub show_shallow{
  my ($self, $depth) = @_;
  print "\t" x $depth, $mag{ ident $self }, "\n";
}

sub compare_deep{
  my ($self, $other) = @_;
  return undef if UNIVERSAL::isa($other, "SBuiltObj");
  return ($mag{ident $self} == $mag{ident $other});
}

sub structure_is{
  my ($self, $struct) = @_;
  my @parts = (ref $struct) ? @$struct : ($struct);
  return 0 unless (@parts == 1);
  return ($mag{ident $self} == $parts[0]);
}

sub structure_ok{
  my ($self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok($self->structure_is($potential_struct), $msg);
}

sub get_structure{
  $mag{ident shift};
}

sub as_int{
  $mag{ident shift};
}

sub can_be_as_int{
  my ( $self, $int ) = @_;
  $mag{ident $self} == $int;
}

sub is_empty{ 0 }


1;

package SInt;
use Perl6::Subs;
use MyFilter;

use SInstance;
our @ISA = qw{SInstance};

sub new{
  my ($package, $val) = @_;
  bless { 'm' => $val}, $package;
}

sub flatten{
  shift->{'m'};
}

sub clone{
  my $self = shift;
  my $ret = SInt->new($self->{'m'});
  $ret;
}

sub show_shallow{
  my ($self, $depth) = @_;
  print "\t" x $depth, $self->{'m'}, "\n";
}

sub compare_deep{
  my ($self, $other) = @_;
  return undef if UNIVERSAL::isa($other, "SBuiltObj");
  return ($self->{'m'} == $other->{'m'});
}

sub structure_is{
  my ($self, $struct) = @_;
  my @parts = (ref $struct) ? @$struct : ($struct);
  return 0 unless (@parts == 1);
  return ($self->{'m'} == $parts[0]);
}

sub structure_ok{
  my ($self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok($self->structure_is($potential_struct), $msg);
}

method get_structure{
  $.m;
}

method as_int(){
  $self->{'m'};
}

method can_be_as_int($int){
  $self->{'m'} == $int;
}

sub is_empty{ 0 }


1;

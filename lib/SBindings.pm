package SBindings;
use strict;
use Carp;
use Class::Std;

my %values_of_of :ATTR( :get<values_of> :set<values_of>);
my %blemishes_of :ATTR( :get<blemishes> );

sub add_blemish{
  my ( $self, $blemish ) = @_;
  UNIVERSAL::isa($blemish, "SBindings::Blemish")
      or croak "Need SBindings::Blemish";
  push (@{ $blemishes_of{ident $self} }, $blemish);
}

1;

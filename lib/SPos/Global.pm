package SPos::Global;
use strict;
use Carp;
use base "SPos";

use Class::Std;
my %finder_of :ATTR( :set<finder> );

sub find_range {
  my ( $self, $built_obj ) = @_;
  $finder_of{ident $self}->find_range($built_obj);
}

1;

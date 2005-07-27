package SPos::Global;
use strict;
use Carp;
use base "SPos";

use Class::Std;
my %finder_of : ATTR( :set<finder> );
my %name_of : ATTR( :set<name> :get<name> );

sub find_range {
    my ( $self, $built_obj ) = @_;
    $finder_of{ ident $self}->find_range($built_obj);
}

1;

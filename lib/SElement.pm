package SElement;
use strict;

our @ISA = qw{SInt};

use Class::Std;
my %left_edge_of :ATTR( :set<left_edge> :get<left_edge> );
my %right_edge_of :ATTR( :set<right_edge> :get<right_edge> );

sub BUILD {
  my ( $self, $id, $opts ) = @_;
  $self->add_cat( $SCat::number::number->build( { mag => $opts->{mag} } ), {} );
}

1;

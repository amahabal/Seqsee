use strict;
use lib 'genlib';
use Test::Seqsee;
BEGIN { plan tests => 4; }


my $e = SElement->create( 5, 3 );
isa_ok $e, "SElement";
is $e->get_mag(), 5;
is $e->get_left_edge(), 3;
is $e->get_right_edge(), 3;

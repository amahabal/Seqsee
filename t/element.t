use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 2; }


my $e = SElement->create( 5 );
isa_ok $e, "SElement";
is $e->get_mag(), 5;

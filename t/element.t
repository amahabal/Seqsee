use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

#use MyFilter;
use SElement;
use SCat::number;

my $e = SElement->new( { mag => 5 } );
isa_ok $e, "SElement";
isa_ok $e, "SInt";
is $e->get_mag(), 5;

instance_of_cat_ok( $e, $SCat::number::number->build( { mag => 5 } ) );

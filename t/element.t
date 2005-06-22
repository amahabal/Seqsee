use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

use MyFilter;
use SElement;
use SCat::number;

my $e = SElement->new(5);
isa_ok $e, "SElement";
isa_ok $e, "SInt";
is $e->{'m'}, 5;

instance_of_cat_ok( $e,  $SCat::number::number->build(mag => 5) );

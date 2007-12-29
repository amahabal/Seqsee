use strict;
use lib 'genlib';
use Test::Seqsee;
plan tests => 2; 

my $elem = SElement->create(2,3);

my $tht = SThought->create( $elem );
isa_ok $tht, "SThought::SElement";

my $tht2 = SThought->create( $elem );
cmp_ok $tht2, 'eq', $tht;
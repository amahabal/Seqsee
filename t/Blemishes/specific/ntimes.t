use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 8; }


my $bl = $S::ntimes;

my $bo1 = SInt->new( { mag => 3 });
my $bo2 = SBuiltObj->new_deep(2, 3);

my $blemished_11 = $bl->blemish($bo1, { n => 4});
my $blemished_12 = $bl->blemish($bo1, { n => 2});

my $blemished_21 = $bl->blemish($bo2, { n => 4});
my $blemished_22 = $bl->blemish($bo2, { n => 2});

$blemished_11->structure_ok([3, 3, 3, 3]);
$blemished_12->structure_ok([3, 3]);
$blemished_21->structure_ok([ [2, 3], [2, 3], [2, 3], [2, 3]]);
$blemished_22->structure_ok([ [2, 3], [2, 3]]);

#### IS INSTANCE

my $bindings;

$bindings = $bl->is_instance( SBuiltObj->new_deep( 5, 5, 5 ));
$bindings->value_ok( 'what', 5 );
$bindings->value_ok( n => 3);

$bindings = $bl->is_instance( SBuiltObj->new_deep( [1, 2], [1, 2] ));
$bindings->value_ok( 'what', [1,2] );
$bindings->value_ok( n => 2);

## FLAT VERSION NOT DEFINED

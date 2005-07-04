use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 7; }

use SBuiltObj;

my $bo;

$bo = SBuiltObj->new_deep(1);
$bo->structure_ok([1]);

$bo = SBuiltObj->new_deep([1]);
$bo->structure_ok([[1]]);
$bo->structure_nok([1]);

$bo = SBuiltObj->new_deep(1, 2, 3);
$bo->structure_ok([1, 2, 3]);
$bo->structure_nok([[1], [2], [3]]);

$bo = SBuiltObj->new_deep([1, 2, 3]);
$bo->structure_ok([[1, 2, 3]]);

$bo = SBuiltObj->new( { items => [1, 2, 3] });
$bo->structure_ok([1, 2, 3]);

use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

#use MyFilter;

use SBuiltObj;

my $bo = new SBuiltObj({items => [1, 2, 3]});
my $bo2 = new_deep SBuiltObj([1, 2], [3, 4]);

ok $bo->has_structure_one_of([1, 2, 3]);
ok $bo->has_structure_one_of([4, 5, 6], [1, 2, 3]);
ok not $bo->has_structure_one_of([1, [2, 3]]);

ok $bo2->has_structure_one_of([1, 2, 3], [[1, 2], [3, 4]]);

use strict;
use blib;
use Test::Seqsee;
use warnings;
BEGIN { plan tests => 17; }

#use MyFilter;

use SBuiltObj;

my $bo = new SBuiltObj( { items => [ 1, 2, 3 ] } );
my $bo2 = new_deep SBuiltObj( [ 1, 2 ], [ 3, 4 ] );

ok $bo->has_structure_one_of( [ 1, 2, 3 ] );
ok $bo->has_structure_one_of( [ 4, 5, 6 ], [ 1, 2, 3 ] );
ok not $bo->has_structure_one_of( [ 1, [ 2, 3 ] ] );

ok $bo2->has_structure_one_of( [ 1, 2, 3 ], [ [ 1, 2 ], [ 3, 4 ] ] );

ok SUtil::compare_deep(2, 2);
ok !SUtil::compare_deep(2, 3);
ok !SUtil::compare_deep(2, [2]);
ok !SUtil::compare_deep([2], 2);
ok SUtil::compare_deep([2], [2]);
ok !SUtil::compare_deep([2], [3]);
ok SUtil::compare_deep([2, 3, [4, 5], [6, [7, 8]]],
		       [2, 3, [4, 5], [6, [7, 8]]]);
ok !SUtil::compare_deep([2, 3, [4, 5], [6, 7, 8]],
			[2, 3, [4, 5], [6, [7, 8]]]);


is SUtil::odd_position(2, 3, 2, 2, 2), 1;
is SUtil::odd_position(3, 2, 2, 2), 0;
undef_ok( SUtil::odd_position(2, 2, 2, 2) );
dies_ok { SUtil::odd_position(2, 3) };
is SUtil::odd_position( qw{foo foo foo bar}), 3;

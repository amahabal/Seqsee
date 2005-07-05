use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 5; }

my $double = $SBlemish::double::double;

my $cat_lit_11 = $SCat::literal::literal->build({structure =>[1, 1]});
my $pos_11 = SPos->new_the($cat_lit_11);

my $bo = SBuiltObj->new_deep([3, 3], [1, 1], [4, 7]);
my $blemished = $bo->apply_blemish_at($double, $pos_11);
$blemished->structure_ok([ [3, 3], [ [1,1], [1,1] ], [4, 7]]);


my $ascending = $SCat::ascending::ascending;
my $mountain  = $SCat::mountain::mountain;

my $bo_asc = $ascending->build( { start => 2, end => 4});
my $bo_mtn = $mountain->build( { foot => 6, peak => 8 });
my $composite = SBuiltObj->new_deep($bo_asc, 5, 6, $bo_mtn);

my $pos_asc = SPos->new_the( $ascending );
my $pos_mtn = SPos->new_the( $mountain );

my $blemished_asc = $composite->apply_blemish_at( $double, $pos_asc );
$blemished_asc->structure_ok( [[ [2, 3, 4], [2, 3, 4]], 5, 6, [6, 7, 8, 7, 6]]);

my $blemished_mtn = $composite->apply_blemish_at( $double, $pos_mtn );
$blemished_mtn->structure_ok([[2, 3, 4], 5, 6, [[6, 7, 8, 7, 6], [6, 7,8, 7, 6]]]);

my $another_composite = SBuiltObj->new_deep([1, 2, 3], [2, 3, 2], [5, 6]);
$blemished_mtn = $another_composite->apply_blemish_at($double, $pos_mtn);
$blemished_mtn->structure_ok([[1, 2, 3], [[2, 3, 2], [2, 3, 2]], [5,6]]);

throws_ok {$another_composite->apply_blemish_at( $double, $pos_asc )}
  "SErr::Pos::MultipleNamed";

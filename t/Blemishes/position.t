use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

use SBuiltObj;
use SPos;
use SBlemish;

use SCat::mountain;
use SBlemish::double;

my $bl = $SBlemish::double::double;

SECOND: {
  my $pos = new SPos 2;
  my $obj = new SBuiltObj(4, 5, 6, 7);
  
  $obj2 = $obj->apply_blemish_at($bl, $pos);
  cmp_deeply([$obj2->flatten], [4, 5, 5, 6, 7]);
  
  cmp_ok($obj, 'ne', $obj2);
}

LAST_BUT_ONE: {
  my $pos = new SPos -2;  
  my $obj = new SBuiltObj(4, 5, 6, 7);
  $obj2 = $obj->apply_blemish_at($bl, $pos);
  cmp_deeply([$obj2->flatten], [4, 5, 6, 6, 7]);
}

NAMED: {
  my $cat = $SCat::mountain::mountain;
  my $bo_mtn = $cat->build(foot => 2, peak => 4);
  my $pos = new SPos "peak";
  my $bo_mtn2 = $bo_mtn->apply_blemish_at($bl, $pos);
  cmp_deeply [$bo_mtn2->flatten], [2, 3, 4, 4, 3, 2];
}

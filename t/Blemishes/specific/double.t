use blib;
use Test::Seqsee;
BEGIN { plan tests => 13; }

use SBuiltObj;
use SCat;
use SPos;

use SBlemish;
use SBlemish::double;

use SCat::mountain;

my $bl      = $SBlemish::double::double;
my $cat_mtn = $SCat::mountain::mountain;

my $bo = $cat_mtn->build(foot => 2, peak => 5);

#################################
# ADDING BLEMISHES

Numbered: {
  my $pos = new SPos 1;
  my $bo_derived = $bo->apply_blemish_at($bl, $pos);
  cmp_deeply [$bo_derived->flatten], [2, 2, 3, 4, 5, 4, 3, 2];
  cmp_deeply $bo_derived->items()->[0]->items, [2, 2], "deep structure okay";
  is scalar(@{$bo_derived->items}), 7, "deep structure okay";
}

Named: {
  my $pos = new SPos "peak";
  my $bo_derived = $bo->apply_blemish_at($bl, $pos);
  cmp_deeply [$bo_derived->flatten], [2, 3, 4, 5, 5, 4, 3, 2];
  cmp_deeply $bo_derived->items()->[3]->items, [5, 5], "deep structure okay";
  is scalar(@{$bo_derived->items}), 7, "deep structure okay";
}

Everywhere: {
 SKIP: {
    skip "positions like 'everywhere' not yet implemented", 3;
    my $pos = new SPos::Range "all";
    my $bo_derived = $bo->apply_blemish_at($bl, $pos);
    cmp_deeply [$bo_derived->flatten], [qw{2 2 3 3 4 4 5 5 4 4 3 3 2 2}];
    cmp_deeply $bo_derived->items()->[4], [4, 4], "deep structure okay";
    is scalar(@{$bo_derived->items}), 7, "deep structure okay";
  }
}

################################
# Testing for blemishes

my $bo2 = new SBuiltObj(3, 3);
my $bo3 = new SBuiltObj(3, 3, 4);
my $bo4 = new_deep SBuiltObj([2, 3], [2, 3]);
my $bo5 = new_deep SBuiltObj([2, 3], [2, 3, 4]);

my $bindings;

$bindings = $bl->is_blemished($bo2);
ok exists($bindings->{what});

$bindings = $bl->is_blemished($bo3);
undef_ok $bindings;

$bindings = $bl->is_blemished($bo4);
ok exists($bindings->{what});

$bindings = $bl->is_blemished($bo5);
undef_ok $bindings;

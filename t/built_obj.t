use Test::More tests=> 16;
use Test::Exception;
use Test::Deep;
use blib;

use_ok("SBuiltObj");

NEW: {
  my $bo = new SBuiltObj();
  $bo->set_items(qw{1 2 3});
  isa_ok($bo, "SBuiltObj");
  cmp_deeply($bo->items, [1,2,3], "Items stored fine");

  my $bo2 = new SBuiltObj(3, 7, 9, 11);
  isa_ok($bo2, "SBuiltObj");
  cmp_deeply($bo2->items, [3, 7, 9, 11]);
}


SUBOBJ_GIVEN_RANGE: {
  my $bo = SBuiltObj->new(2, 4, 6, 8, 10);
  my $count = 0;
  for my $pair ([ [0..3],   [2, 4, 6, 8]  ],
		[ [2],      [6]           ],
		[ [],       []            ],
		[ [3, 4, 3, 1], [8, 10, 8, 4]],
	       ) {
    $count++;
    my $so = $bo->subobj_given_range($pair->[0]);
    isa_ok($so, "SBuiltObj", "subobj given range @{$pair->[0]}: ISA");
    cmp_deeply($so->items, $pair->[1], "subobj given range @{$pair->[0]}: deep comp");
  }
 OUT_OF_RANGE: {
    my $so = $bo->subobj_given_range([7]);
    ok(not(defined $so));
    $so = $bo->subobj_given_range([1, 7]);
    ok(not(defined $so));
  }
}


SPLICING: {
  my $bo = SBuiltObj->new(7, 8, 9, 10, 11);

  $bo->splice(2, 2, 4, 5, 6);
  cmp_deeply($bo->items, [7, 8, 4, 5, 6, 11]);

}

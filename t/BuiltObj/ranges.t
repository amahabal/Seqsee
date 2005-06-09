use blib;
use Test::Seqsee;

use SBuiltObj;

BEGIN { plan tests => 10; }

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

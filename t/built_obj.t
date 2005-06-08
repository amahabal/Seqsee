use blib;
use Test::Seqsee;

use SCat;

BEGIN { plan tests => 24; }



BEGIN { use_ok("SBuiltObj"); }

NEW: {
  my $bo = new SBuiltObj();
  $bo->set_items(qw{1 2 3});
  isa_ok($bo, "SBuiltObj");
  cmp_deeply($bo->items, [1,2,3], "Items stored fine");

  my $bo2 = new SBuiltObj(3, 7, 9, 11);
  isa_ok($bo2, "SBuiltObj");
  cmp_deeply($bo2->items, [3, 7, 9, 11]);
}

CATS: {
  my $bo = new SBuiltObj(1, 2, 3);
  dies_ok { $bo->add_cat(); } "add_cat needs arguments";
  dies_ok { $bo->add_cat("foo") } "add_cat first argument must be isa SCat";
  my $cat1 = new SCat;
  my $cat2 = SCat->new()->add_attributes(qw/start/);
  lives_ok { $bo->add_cat($cat1) } "add_cat lives okay with cat arg";
  dies_ok { $bo->add_cat($cat2, foo => 3)} "if bindings present, they must be attributes";
  lives_ok { $bo->add_cat($cat2, start => 3)} "add_cat okay if bindings really are attributes";
  
  my @cats = $bo->get_cats();
  cmp_deeply(\@cats, [$cat2, $cat1]);
  undef_ok( $bo->get_cat_bindings($cat2)->{foo} );
  is( $bo->get_cat_bindings($cat2)->{start}, 3 );

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

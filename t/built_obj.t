use blib;
use Test::Seqsee;

use SCat;

BEGIN { plan tests => 37; }



BEGIN { use_ok("SBuiltObj"); }

NEW: {
  my $bo = new SBuiltObj();
  $bo->set_items(qw{1 2 3});
  isa_ok($bo, "SBuiltObj");
  cmp_deeply($bo->items, [1,2,3], "Items stored fine");

  my $bo2 = new SBuiltObj(3, 7, 9, 11);
  isa_ok($bo2, "SBuiltObj");
  cmp_deeply($bo2->items, [3, 7, 9, 11]);

 CLONE: {
    my $bo2 = $bo->clone;
    isa_ok $bo2, "SBuiltObj";
    cmp_deeply $bo2->items, [1, 2, 3];
  }
  
 CLONE_NEW: {
    my $bo3 = new SBuiltObj($bo, 5, $bo);
    isa_ok $bo3, "SBuiltObj";
    my @items = @{ $bo3->items };
    isa_ok $items[0], "SBuiltObj";
    cmp_ok($items[0], 'ne', $bo);
    cmp_ok($items[2], 'ne', $bo);
    cmp_ok($items[0], 'ne', $items[2]);
    cmp_deeply([$bo3->flatten], [1, 2, 3, 5, 1, 2, 3]);
  }
}

NEW_DEEP: {
  my $bo  = new_deep SBuiltObj(1, 2, 3);
  my $bo2 = new_deep SBuiltObj([1, 2], 3);
  my $bo3 = new_deep SBuiltObj(1, [2, 3], $bo, $bo2);
  cmp_deeply [$bo3->flatten], [qw{1 2 3 1 2 3 1 2 3}];
  is scalar(@{$bo->items}), 3;
  is scalar(@{$bo2->items}), 2;
  is scalar(@{$bo3->items}), 4;
  is $bo3->items()->[3]->items()->[0]->items()->[1], 2;
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
  
  my @cats = sort $bo->get_cats();
  cmp_deeply(\@cats, [sort($cat1, $cat2)]);
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

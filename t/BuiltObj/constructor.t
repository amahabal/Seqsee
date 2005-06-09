use blib;
use Test::Seqsee;

use SCat;
use SBuiltObj;

BEGIN { plan tests => 17; }



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




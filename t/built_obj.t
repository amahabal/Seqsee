use Test::More tests=> 3;
use Test::Exception;
use Test::Deep;
use blib;

use_ok("SBuiltObj");

my $bo = new SBuiltObj();
$bo->set_items(qw{1 2 3});

isa_ok($bo, "SBuiltObj");
cmp_deeply($bo->items, [1,2,3], "Items stored fine");


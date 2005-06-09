use blib;
use Test::Seqsee;
BEGIN { plan tests => 2; }

use SBuiltObj;

my $bo = new SBuiltObj(1, 2, 3);
ok($bo->structure_is([1, 2, 3]));
$bo->structure_ok([1, 2, 3]);

# XXX MORE TESTS NEEDED HERE

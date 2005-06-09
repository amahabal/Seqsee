use blib;
use Test::Seqsee;
BEGIN { plan tests => 1; }

use SBuiltObj;

my $bo = SBuiltObj->new(7, 8, 9, 10, 11);

$bo->splice(2, 2, 4, 5, 6);
cmp_deeply([$bo->flatten], [7, 8, 4, 5, 6, 11]);


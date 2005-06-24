use blib;
use Test::Seqsee;
BEGIN { plan tests => 1; }

use SBuiltObj;
use SInt;

my $bo = SBuiltObj->new({items => [7, 8, 9, 10, 11]});

$bo->splice(2, 2,[ map { SInt->new({mag => $_}) } (4, 5, 6) ]);
$bo->structure_ok([7, 8, 4, 5, 6, 11]);


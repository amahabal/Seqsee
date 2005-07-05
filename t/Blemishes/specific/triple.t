use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 5; }

my $bl = $S::triple;

my $bo1 = SBuiltObj->new_deep(3);
my $bo2 = SBuiltObj->new_deep(2,3);

#XXX changed next line.
# Having trouble keeping depth straight. Need sanity
my $blemished_1 = $bl->blemish(SInt->new({mag => 3}));
my $blemished_2 = $bl->blemish($bo2);

$blemished_1->structure_ok([3, 3, 3]);
#$blemished_1->show;
$blemished_2->structure_ok([ [2, 3], [2, 3], [2, 3] ]);


## IS_INSTANCE
my $bindings;

{
  $bindings = $bl->is_instance( SBuiltObj->new_deep(5, 5, 5) );
  ok $bindings;
  $bindings->value_ok('what', 5);
  

  my $bo = SBuiltObj->new_deep(1, 2, 1, 2, 1, 2);
  $bindings = $bl->is_instance_flat( @{ $bo->items } );
  $bindings->value_ok(what => [1, 2]);

}

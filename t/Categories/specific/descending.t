use blib;
use Test::Seqsee;
BEGIN { plan tests=> 12; }

use SBuiltObj;
use SBindings;
use SCat;

BEGIN{
  use_ok "SCat::descending";
}

my $cat = $SCat::descending::descending;
isa_ok($cat, "SCat" );

BUILDING: {
  my $ret;
  $ret = $cat->build(start => 5, end => 2);
  isa_ok($ret, "SBuiltObj");
  $ret->structure_ok([5, 4, 3, 2], "start => 5, end => 2");
  $ret = $cat->build(start => 2, end => 2);
  $ret->structure_ok([2], "start => 2, end => 2");
  $ret = $cat->build(start => 1, end => 2);
  $ret->structure_ok([], "start => 1, end => 2");
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance(SBuiltObj->new(4, 3, 2));
  isa_ok($bindings, "SBindings");
  is($bindings->{start}, 4);
  is($bindings->{end}, 2);

  $bindings = $cat->is_instance(SBuiltObj->new(2));
  is($bindings->{start}, 2);
  is($bindings->{end}, 2);

  $bindings = $cat->is_instance();
  isa_ok($bindings, "SBindings");
}

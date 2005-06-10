use blib;
use Test::Seqsee;
BEGIN { plan tests=> 12; }

use SBuiltObj;
use SBindings;
use SCat;

BEGIN{
  use_ok "SCat::ascending";
}

my $cat = $SCat::ascending::ascending;
isa_ok($cat, "SCat" );

BUILDING: {
  my $ret;
  $ret = $cat->build(start => 2, end => 5);
  isa_ok($ret, "SBuiltObj");
  $ret->structure_ok([2, 3, 4, 5], "start => 2, end => 5");
  $ret = $cat->build(start => 2, end => 2);
  $ret->structure_ok([2], "start => 2, end => 2");
  $ret = $cat->build(start => 2, end => 1);
  $ret->structure_ok([], "start => 2, end => 1");
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance(2, 3, 4);
  isa_ok($bindings, "SBindings");
  is($bindings->{start}, 2);
  is($bindings->{end}, 4);

  $bindings = $cat->is_instance(2);
  is($bindings->{start}, 2);
  is($bindings->{end}, 2);

  $bindings = $cat->is_instance();
  isa_ok($bindings, "SBindings");
}

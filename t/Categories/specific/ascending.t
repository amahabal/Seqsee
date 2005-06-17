use blib;
use Test::Seqsee;
BEGIN { plan tests=> 16; }

use SBuiltObj;
use SBindings;
use SCat;

use SBlemish::double;
use SPos;

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

BLEMISHED_IS_INST: {
  my $bindings;
  $bindings = $cat->is_instance(
	$cat->build(start => 3, end => 8)
		->apply_blemish_at(	$SBlemish::double::double,
					SPos->new(2) ));
  isa_ok $bindings, "SBindings";
  is $bindings->{start}, 3;
  is $bindings->{end},   8;
  TODO: {
	local $TODO = "instancer does not yet add blemish bindings";
	ok $bindings->{_blemish};
  }
}

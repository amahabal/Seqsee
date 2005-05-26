use Test::More tests => 14;
use Test::Exception;
use Test::Deep;
use blib;

use SBuiltObj;
use SBindings;
use SCat;

BEGIN{
  use_ok "SCat::mountain";
}

my $cat = $SCat::mountain::mountain;
isa_ok($cat, "SCat");

BUILDING: {
  my $ret;
  $ret = $cat->build(foot => 1, peak => 5);
  isa_ok($ret, "SBuiltObj");
  cmp_deeply($ret->items, [qw{1 2 3 4 5 4 3 2 1}]);

  $ret = $cat->build(foot => 4, peak => 5);
  cmp_deeply($ret->items, [qw{4 5 4}]);
  
  $ret = $cat->build(foot => 5, peak => 5);
  cmp_deeply($ret->items, [qw{5}]);

  $ret = $cat->build(foot => 6, peak => 5);
  cmp_deeply($ret->items, [qw{}]);
  
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance(1, 2, 3, 2, 1);
  isa_ok($bindings, "SBindings");
  is($bindings->{foot}, 1);
  is($bindings->{peak}, 3);

  $bindings = $cat->is_instance(5);
  is($bindings->{foot}, 5);
  is($bindings->{peak}, 5);
  
  $bindings = $cat->is_instance(5, 6);
  ok(not(defined $bindings));

  $bindings = $cat->is_instance();
  isa_ok($bindings, "SBindings");
}

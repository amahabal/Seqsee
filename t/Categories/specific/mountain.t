use blib;
use Test::Seqsee;
BEGIN { 
  plan tests => 16;
}

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
  instance_of_cat_ok $ret, $cat;
  $ret->structure_ok([qw{1 2 3 4 5 4 3 2 1}]);

  $ret = $cat->build(foot => 4, peak => 5);
  $ret->structure_ok([qw{4 5 4}]);
  
  $ret = $cat->build(foot => 5, peak => 5);
  $ret->structure_ok([qw{5}]);

  $ret = $cat->build(foot => 6, peak => 5);
  instance_of_cat_ok $ret, $cat;
  $ret->structure_ok([]);
  
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance(SBuiltObj->new({items => [1, 2, 3, 2, 1]}));
  isa_ok($bindings, "SBindings");
  is($bindings->{foot}, 1);
  is($bindings->{peak}, 3);

  $bindings = $cat->is_instance(SBuiltObj->new({items => [5]}));
  is($bindings->{foot}, 5);
  is($bindings->{peak}, 5);
  
  $bindings = $cat->is_instance(SBuiltObj->new({items=>[5, 6]}));
  undef_ok($bindings);

  $bindings = $cat->is_instance();
  isa_ok($bindings, "SBindings");
}


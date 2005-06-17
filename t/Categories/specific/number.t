use blib;
use Test::Seqsee;
BEGIN { plan tests => 8; }

use SBuiltObj;
use SBindings;
use SCat;

use SCat::number;
use SBlemish::double;

my $cat = $SCat::number::number;
my $double_blemish = $SBlemish::double::double;
isa_ok $cat, "SCat";

BUILDING: {
  my $cat_5 = $cat->build(mag => 5);
  my $cat_5_copy = $cat->build(mag => 5);
  is $cat_5, $cat_5_copy, "memoized";
  isa_ok $cat_5, "SCat";
  instance_of_cat_ok $cat_5, $cat;
  
 BUILD: {
    $cat_5->build()->structure_ok([5]); 
  }
  
 IS_INSTANCE: {
    my $bindings;
    my $bo_is    = new SBuiltObj(5);
    my $bo_isnt  = new SBuiltObj(6);
    my $bo_is_bl = $double_blemish->blemish(SBuiltObj->new(5));

    $bindings = $cat_5->is_instance($bo_is);
    isa_ok $bindings, "SBindings";

    $bindings = $cat_5->is_instance($bo_isnt);
    undef_ok $bindings;

    $bindings = $cat_5->is_instance($bo_is_bl);
    isa_ok $bindings, "SBindings";

  }
}

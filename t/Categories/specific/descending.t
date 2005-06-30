use blib;
use Test::Seqsee;
BEGIN { plan tests => 10; }

use SBuiltObj;
use SCat;

BEGIN {
  use_ok "SCat::descending";
}

my $cat = $SCat::descending::descending;
isa_ok( $cat, "SCat" );

BUILDING: {
  my $ret;
  $ret = $cat->build( { start => 5, end => 2 } );
  isa_ok( $ret, "SBuiltObj" );
  $ret->structure_ok( [ 5, 4, 3, 2 ], "start => 5, end => 2" );
  $ret = $cat->build( { start => 2, end => 2 } );
  $ret->structure_ok( [2], "start => 2, end => 2" );
  $ret = $cat->build( { start => 1, end => 2 } );
  $ret->structure_ok( [], "start => 1, end => 2" );
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance( SBuiltObj->new( { items => [ 4, 3, 2 ] } ) );
  $bindings->value_ok(start => 4);
  $bindings->value_ok(end => 2);

  $bindings = $cat->is_instance( SBuiltObj->new( { items => [2] } ) );
  $bindings->value_ok(start => 2);
  $bindings->value_ok(end => 2);

}

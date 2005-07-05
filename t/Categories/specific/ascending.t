use blib;
use Test::Seqsee;
BEGIN { plan tests => 27; }

BEGIN {
  use_ok "SCat::ascending";
}

my $cat = $S::ascending;
isa_ok( $cat, "SCat" );

BUILDING: {
  my $ret;
  $ret = $cat->build( { start => 2, end => 5 } );
  isa_ok( $ret, "SBuiltObj" );
  $ret->structure_ok( [ 2, 3, 4, 5 ], "start => 2, end => 5" );
  $ret = $cat->build( { start => 2, end => 2 } );
  $ret->structure_ok( [2], "start => 2, end => 2" );
  $ret = $cat->build( { start => 2, end => 1 } );
  $ret->structure_ok( [], "start => 2, end => 1" );
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance( SBuiltObj->new( { items => [ 2, 3, 4 ] } ) );
  $bindings->value_ok(start => 2);
  $bindings->value_ok(end   => 4);

  $bindings = $cat->is_instance( SBuiltObj->new( { items => [2] } ) );
  $bindings->value_ok(start => 2);
  $bindings->value_ok(end   => 2);


}

BLEMISHED_IS_INST: {
  my $bindings;
  $bindings =
    $cat->is_instance( $cat->build( { start => 3, end => 8 } )
      ->apply_blemish_at( $S::double, SPos->new(2) ) );
  $bindings->value_ok(start => 3);
  $bindings->value_ok(end   => 8);
  
  blemished_where_ok     ( $bindings, [1] );
  blemished_starred_okay ( $bindings, [4] );
  blemished_real_okay    ( $bindings, [[4, 4]]);
  $bindings->blemished_ok;

  my $very_blemished_obj =
    $cat->build( { start => 3, end => 8 } )
    ->apply_blemish_at( $S::double, SPos->new(1) )
    ->apply_blemish_at( $S::double, SPos->new(-1) );
  $very_blemished_obj->structure_ok( [ [ 3, 3 ], 4, 5, 6, 7, [ 8, 8 ] ] );

  $bindings = $cat->is_instance($very_blemished_obj);
  $bindings->value_ok(start => 3);
  $bindings->value_ok(end   => 8);
  blemished_where_ok     ( $bindings, [0, 5] );
  blemished_starred_okay ( $bindings, [3, 8] );
  blemished_real_okay    ( $bindings, [[3, 3], [8, 8]]);
  $bindings->blemished_ok;
  

  $very_blemished_obj =
    $cat->build( { start => 3, end => 8 } )
    ->apply_blemish_at( $S::double, SPos->new(1) )
    ->apply_blemish_at( $S::double, SPos->new(1) );
  $very_blemished_obj->structure_ok(
    [ [ [ 3, 3 ], [ 3, 3 ] ], 4, 5, 6, 7, 8 ] );

  $bindings = $cat->is_instance($very_blemished_obj);
  $bindings->value_ok(start => 3);
  $bindings->value_ok(end   => 8);
  $bindings->blemished_ok;


}


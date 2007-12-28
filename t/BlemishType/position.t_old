use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }


my $bl = $S::double;

SECOND: {
  my $pos = new SPos 2;
  my $obj = new SBuiltObj( { items => [ 4, 5, 6, 7 ] } );

  $obj2 = $obj->apply_blemish_at( $bl, $pos );
  $obj2->structure_ok( [ 4, [ 5, 5 ], 6, 7 ] );

  cmp_ok( $obj, 'ne', $obj2 );
}

LAST_BUT_ONE: {
  my $pos = new SPos - 2;
  my $obj = new SBuiltObj( { items => [ 4, 5, 6, 7 ] } );
  $obj2 = $obj->apply_blemish_at( $bl, $pos );
  $obj2->structure_ok( [ 4, 5, [ 6, 6 ], 7 ] );
}

NAMED: {
  my $cat     = $S::mountain;
  my $bo_mtn  = $cat->build( { foot => 2, peak => 4 } );
  my $pos     = new SPos "peak";
  my $bo_mtn2 = $bo_mtn->apply_blemish_at( $bl, $pos );
  $bo_mtn2->structure_ok( [ 2, 3, [ 4, 4 ], 3, 2 ] );
}

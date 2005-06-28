use blib;
use Test::Seqsee;

use SCat;
use SBuiltObj;

BEGIN { plan tests => 24; }

NEW: {
  my $bo = new SBuiltObj();
  $bo->set_items( [qw{1 2 3}] );
  isa_ok( $bo, "SBuiltObj" );
  $bo->structure_ok( [ 1, 2, 3 ], "Items stored fine" );
  isa_ok $bo->items()->[0], "SInt";

  my $bo2 = new SBuiltObj( { items => [ 3, 7, 9, 11 ] } );
  isa_ok( $bo2, "SBuiltObj" );
  $bo2->structure_ok( [ 3, 7, 9, 11 ] );

CLONE: {
    my $bo2 = $bo->clone;
    isa_ok $bo2, "SBuiltObj";
    $bo2->structure_ok( [ 1, 2, 3 ] );
    isa_ok $bo2->items()->[0], "SInt";
  }

CLONE_NEW: {
    my $bo3 = new SBuiltObj( { items => [ $bo, 5, $bo ] } );
    isa_ok $bo3, "SBuiltObj";
    my @items = @{ $bo3->items };
    isa_ok $items[0], "SBuiltObj";
    cmp_ok( $items[0], 'ne', $bo );
    cmp_ok( $items[2], 'ne', $bo );
    cmp_ok( $items[0], 'ne', $items[2] );
    $bo3->structure_ok( [ [ 1, 2, 3 ], 5, [ 1, 2, 3 ] ] );
    isa_ok $items[0]->items()->[0], "SInt";
  }
}

NEW_DEEP: {
  my $bo = new_deep SBuiltObj( 1, 2, 3 );
  my $bo2 = new_deep SBuiltObj( [ 1, 2 ], 3 );
  my $bo3 = new_deep SBuiltObj( 1, [ 2, 3 ], $bo, $bo2 );
  $bo3->structure_ok( [ 1, [ 2, 3 ], [ 1, 2, 3 ], [ [ 1, 2 ], 3 ] ] );
  is scalar( @{ $bo->items } ),  3;
  is scalar( @{ $bo2->items } ), 2;
  is scalar( @{ $bo3->items } ), 4;
  isa_ok $bo3->items()->[3]->items()->[0]->items()->[1], "SInt";
  is $bo3->items()->[3]->items()->[0]->items()->[1]->get_mag(), 2;

  my $structure = $bo3->get_structure;
  is $structure->[0], 1;
  is $structure->[1][1], 3;
  cmp_deeply $structure, [ 1, [ 2, 3 ], [ 1, 2, 3 ], [ [ 1, 2 ], 3 ] ];
}


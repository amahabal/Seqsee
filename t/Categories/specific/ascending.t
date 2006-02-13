use blib;
use Test::Seqsee;
use Smart::Comments;
BEGIN { plan tests => 13; }

BEGIN {
  use_ok "SCat::ascending";
}

my $cat = $S::ASCENDING;
isa_ok( $cat, "SCat::OfObj" );

BUILDING: {
  my $ret;
  $ret = $cat->build( { start => 2, end => 5 } );
  isa_ok( $ret, "SObject" );
  $ret->structure_ok( [ 2, 3, 4, 5 ], "start => 2, end => 5" );
  $ret = $cat->build( { start => 2, end => 2 } );
  $ret->structure_ok( [2], "start => 2, end => 2" );
  $ret = $cat->build( { start => 2, end => 1 } );
  $ret->structure_ok( [], "start => 2, end => 1" );
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance( SObject->create( 2,3,4 ));
  cmp_ok( $bindings->get_binding('start'), 'eq', 2 );
  cmp_ok( $bindings->get_binding('end'), 'eq', 4 );

  $bindings = $cat->is_instance( SObject->create(2));
  cmp_ok( $bindings->get_binding('start'), 'eq', 2 );
  cmp_ok( $bindings->get_binding('end'), 'eq', 2 );
}

BLEMISHED_IS_INST: {
  my $bindings;
  my $meto_type = SMetonymType->new( 
      { category => $S::SAMENESS,
        name => 'each',
        info_loss =>  { length => 2 },
            });
  ## $meto_type
  my $object = $cat->build( { start => 3, end => 8});
  ## $object->get_structure
  $object = $object->apply_blemish_at($meto_type,SPos->new(2));
  ## $object->get_structure
  ok( $object->can_be_seen_as(SObject->create(3,4,5,6,7,8)), "Can be seen as" );

  $bindings =
    $cat->is_instance( $object );
  ## $bindings
  cmp_ok( $bindings->get_binding('start'), 'eq', 3 );
  cmp_ok( $bindings->get_binding('end'), 'eq', 8 );
  
}


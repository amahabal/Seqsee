use blib;
use Test::Seqsee;
use Smart::Comments;
BEGIN { plan tests => 25; }

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
  ## $ret
  ## $ret->get_structure
  $ret->structure_ok( 2, "start => 2, end => 2" );
  $ret = $cat->build( { start => 2, end => 1 } );
  $ret->structure_ok( [], "start => 2, end => 1" );
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance( SObject->create( 2,3,4 ));
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 2 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 4 );

  $bindings = $cat->is_instance( SObject->create(2));
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 2 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 2 );
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
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 3 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 8 );
  
  $object = SObject->QuickCreate([3,4,[5,5],6,7,8]);
  ## $object
  ok( $object->can_be_seen_as(SObject->create(3,4,5,6,7,8)), "Can be seen as" );

  $bindings =
    $cat->is_instance( $object );
  ## $bindings
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 3 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 8 );
  cmp_ok( $bindings->get_metonymy_mode(), 'eq', $METO_MODE::SINGLE);

}

BLEMISHED_IS_INST_TRIVIAL: {
  my $bindings;
  my $meto_type = SMetonymType->new( 
      { category => $S::SAMENESS,
        name => 'each',
        info_loss =>  { length => 1 },
            });
  ## $meto_type
  my $object = $cat->build( { start => 3, end => 5});
  ## $object->get_structure
  $object = $object->apply_blemish_at($meto_type,SPos->new(2));
  ## $object->get_structure
  ok( $object->can_be_seen_as(SObject->create(3,4,5)), "Can be seen as" );

  $bindings =
    $cat->is_instance( $object );
  ## $bindings
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 3 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 5 );
  cmp_ok( $bindings->get_metonymy_mode(), 'eq', $METO_MODE::SINGLE);

}

BLEMISHED_IS_INST_TRIVIAL2: {
  my $bindings;
  my $meto_type = SMetonymType->new( 
      { category => $S::SAMENESS,
        name => 'each',
        info_loss =>  { length => 1 },
            });
  ## $meto_type
  my $object = $cat->build( { start => 3, end => 3});
  ## $object->get_structure
  $object = $object->apply_blemish_at($meto_type,SPos->new(1));
  ## $object->get_structure
  ok( $object->can_be_seen_as(SObject->create(3)), "Can be seen as" );

  $bindings =
    $cat->is_instance( $object );
  ## $bindings
  cmp_ok( $bindings->GetBindingForAttribute('start'), 'eq', 3 );
  cmp_ok( $bindings->GetBindingForAttribute('end'), 'eq', 3 );
  cmp_ok( $bindings->get_metonymy_mode(), 'eq', $METO_MODE::SINGLE);

}


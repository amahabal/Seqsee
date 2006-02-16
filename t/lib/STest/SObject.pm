package STest::SObject;
use base qw{Test::Class};
use Test::More;
use Test::Deep;
use Test::Exception;
use Smart::Comments;
use S;

sub create :Test(6) {
    my @test_set = 
        (
            [ [1],               1                 ],
            [ [1,1],             [1,1]               ],
            [ [[1]],             1                 ],
            [ [2, [3]],          [2,3]               ],
            [ [2, [[[3]]]],      [2,3]               ],
            [ [[[[[2,3]]]]],     [2,3]               ],
                );
    for (@test_set) {
        cmp_deeply( SObject->create(@{$_->[0]})->get_structure(), $_->[1] );
    }
}

sub create_clone :Test(5){
    my $object = SObject->create(1,2,3);
    my $object2 = SObject->create( $object );
    isa_ok ($object2, "SObject");
    cmp_ok($object, 'ne', $object2);

    my $object3 = SObject->create($object, $object);
    isa_ok ($object3, "SObject");
    cmp_ok($object, 'ne', $object3->[0]);
    $object3->structure_ok([[1,2,3], [1,2,3]]);
}


sub group_p : Test(4) {
    my @test_set = 
        (
            [ [1, 2], 1],
            [ [1], 0],
            [ [[1]], 0],
            [ [[1,2]], 1],
                );
    for (@test_set) {
        cmp_ok( SObject->create(@{$_->[0]})->get_group_p(), '==',  $_->[1] );
    }
}

sub get_flattened :Test(3) {
    my @test_set = 
        (
            [ [1],               [1]                 ],
            [ [1,[1,2]],         [1,1,2]             ],
            [ [1,[2, [3, 4], 5]],[1,2,3,4,5]         ],
                );
    for (@test_set) {
        cmp_deeply( SObject->create(@{$_->[0]})->get_flattened(), $_->[1] );
    }
}

sub quik_create :Test(16) {
    my $object = SObject->quik_create([2,3,4], $S::ASCENDING);
    $object->is_of_category_ok($S::ASCENDING);
    
    $object = SObject->quik_create([2,3,[4,4]]);
    $object->structure_ok([2,3,[4,4]]);

    my $subobject = $object->[2];
    $subobject->is_of_category_ok( $S::SAMENESS );

    my $metonym = $subobject->get_metonym;
    ok ($metonym);
    cmp_ok( $metonym->get_category(), 'eq', $S::SAMENESS);
    cmp_ok( $metonym->get_name(), 'eq', "each");
    cmp_ok( $metonym->get_starred()->get_structure, 'eq', 4);
    $metonym->get_unstarred()->structure_ok( [4, 4]);

    my $object2 = SObject->quik_create([2,3,[4,4],5]);
    ok( $object2->can_be_seen_as(SObject->create(2,3,4,5)), );
    ok( $object2->can_be_seen_as([2,3,4,5], ));
    ## $object2->get_structure
    ok( $S::ASCENDING->is_instance($object2), );

    $object2->is_of_category_ok($S::ASCENDING);

    $object2 = SObject->quik_create([2,3,[4,4]]);
    ok( $object2->can_be_seen_as(SObject->create(2,3,4)), );
    ok( $object2->can_be_seen_as([2,3,4], ));
    ## $object2->get_structure
    ok( $S::ASCENDING->is_instance($object2), );

    $object2->is_of_category_ok($S::ASCENDING);


}



# method: is_sane
# Checks that all or none of the items are SAnchored. 
#
#    If all are SAnchored, checks that their left and right edges are defined, and when composed, this object shall not have holes in it.
#     
#    This call should work on the items, not the composed object. The composed object will come into existence once the sanity passes.
sub is_sane :Test(9){
    my $o_unanch1 = SObject->create(2,3);
    my $o_unanch2 = SObject->create(2,3);
    my $e1 = SElement->create(3,0)->set_edges(4,4);
    my $e2 = SElement->create(3,0)->set_edges(5,5);
    my $e3 = SElement->create(3,0)->set_edges(6,6);
    my $e4 = SElement->create(3,0)->set_edges(7,7);
    my $e5 = SElement->create(3,0)->set_edges(8,8);
    my $o_anch1 = SAnchored->create( $e1, $e2, $e3 );

    cmp_ok($o_anch1->get_left_edge(), 'eq', 4);
    cmp_ok($o_anch1->get_right_edge(), 'eq', 6);

    my $o_anch2 = SAnchored->create($o_anch1, $e4);
    cmp_ok($o_anch2->get_left_edge(), 'eq', 4);
    cmp_ok($o_anch2->get_right_edge(), 'eq', 7);

    my $o_anch3 = SAnchored->create($e4, $o_anch1);
    cmp_ok($o_anch3->get_left_edge(), 'eq', 4);
    cmp_ok($o_anch3->get_right_edge(), 'eq', 7);

    throws_ok { SAnchored->create( $o_anch1, $e5 )} SErr::HolesHere, "There are holes here!";

    throws_ok { SAnchored->create( $o_unanch1, $e5 )} SErr, "There is an unachored object here";

    # Group formed from a single element is just itself...
    my $WSO_a = SAnchored->create($e5);
    ok( $WSO_a eq $e5 , );


    #throws_ok { SAnchored->create( $e5 );} SErr, "A grop creation should not be attempted based on a single object";

}

1;

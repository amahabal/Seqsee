package STest::SObject;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;

sub create :Test(6) {
    my @test_set = 
        (
            [ [1],               [1]                 ],
            [ [1,1],             [1,1]               ],
            [ [[1]],             [1]                 ],
            [ [2, [3]],          [2,3]               ],
            [ [2, [[[3]]]],      [2,3]               ],
            [ [[[[[2,3]]]]],     [2,3]               ],
                );
    for (@test_set) {
        cmp_deeply( SObject->create(@{$_->[0]})->get_structure(), $_->[1] );
    }
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

sub quik_create :Test(7) {
    my $object = SObject->quik_create([2,3,[4,4]]);
    $object->structure_ok([2,3,[4,4]]);

    my $subobject = $object->[2];
    $subobject->is_of_category_ok( $S::SAMENESS );

    my $metonym = $subobject->get_metonym;
    ok ($metonym);
    cmp_ok( $metonym->get_category(), 'eq', $S::SAMENESS);
    cmp_ok( $metonym->get_name(), 'eq', "each");
    cmp_ok( $metonym->get_starred(), 'eq', 4);
    $metonym->get_unstarred()->structure_ok( [4, 4]);

}

1;

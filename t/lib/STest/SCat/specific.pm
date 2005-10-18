package STest::SCat::specific;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use SObject;
use SCat::OfObj;

use Smart::Comments;

sub ascending_build :Test(6){
    my $cat = $S::ASCENDING;

    my @build_test = (
        [ { start => 2, end => 5}, [2,3,4,5] ],
        [ { start => 5, end => 5}, [5] ],
        [ { start => 6, end => 5}, [] ],
            );
    for (@build_test) {
        my $object = $cat->build($_->[0]);
        $object->structure_ok($_->[1]);
        $object->is_of_category_ok( $cat );
    }

}

sub ascending_is_instance :Test(5){
    diag "ASCENDING IS INSTANCE";
    my $cat = $S::ASCENDING;
    my $object;
    my @test_objects = (
        [1, 2, 3],
        [1],
        [1, [2, 2], 3],
        [[1,1], 2, 3],
        [[1,1], [2,2], [3,3]],
            );
    for (@test_objects) {
        my $object = SObject->quik_create($_);
        ok( $cat->is_instance($object));
    }

}


sub descending_build :Test(6){
    my $cat = $S::DESCENDING;

    my @build_test = (
        [ { start => 5, end => 2}, [5,4,3,2] ],
        [ { start => 5, end => 5}, [5] ],
        [ { start => 4, end => 5}, [] ],
            );
    for (@build_test) {
        my $object = $cat->build($_->[0]);
        $object->structure_ok($_->[1]);
        $object->is_of_category_ok( $cat );
    }

}

sub descending_is_instance :Test(5){
    diag "DESCENDING IS INSTANCE";
    my $cat = $S::DESCENDING;
    my $object;
    my @test_objects = (
        [3,,2,1],
        [1],
        [3, [2, 2], 1],
        [[3,3], 2, 1],
        [[3,3], [2,2], [1,1]],
            );
    for (@test_objects) {
        my $object = SObject->quik_create($_);
        ok( $cat->is_instance($object));
    }

}


sub mountain_build :Test(6){
    my $cat = $S::MOUNTAIN;

    my @build_test = (
        [ { foot => 5, peak => 7}, [5,6,7,6,5] ],
        [ { foot => 5, peak => 5}, [5] ],
        [ { foot => 6, peak => 5}, [] ],
            );
    for (@build_test) {
        my $object = $cat->build($_->[0]);
        $object->structure_ok($_->[1]);
        $object->is_of_category_ok( $cat );
    }

}

sub mountain_is_instance :Test(5){
    diag "Mountain IS INSTANCE";
    my $cat = $S::MOUNTAIN;
    my $object;
    my @test_objects = (
        [1, 2, 3,2,1],
        [1],
        [1, [2, 2], 3,2,1],
        [[1,1], 2, 3,2,1],
        [[1,1], [2,2], [3,3], [2,2], [1,1]],
            );
    for (@test_objects) {
        my $object = SObject->quik_create($_);
        ok( $cat->is_instance($object));
    }

}

sub sameness_build :Test(6){
    my $cat = $S::SAMENESS;

    my @build_test = (
        [ { each => 2, length => 5}, [2,2,2,2,2] ],
        [ { each => 5, length => 0}, [] ],
        [ { each => SObject->create(1,2), length => 3}, [[1,2],[1,2], [1,2]] ],
            );
    for (@build_test) {
        my $object = $cat->build($_->[0]);
        $object->structure_ok($_->[1]);
        $object->is_of_category_ok( $cat );
    }

}

sub sameness_is_instance :Test(4){
    diag "SAMENESS IS INSTANCE";
    my $cat = $S::SAMENESS;
    my $object;
    my @test_objects = (
        [1, 1,1],
        [1],
        [[1,2,3], [1,2,3]],
        [1, [1,1]],
            );
    for (@test_objects) {
        my $object = SObject->quik_create($_);
        ok( $cat->is_instance($object));
    }

}


1;

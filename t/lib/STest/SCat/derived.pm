package STest::SCat::derived;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use SObject;
use SCat::OfObj;

use Smart::Comments;
use Carp;

my $derived_assuming = $S::ASCENDING->derive_assuming( { start => 1} );


sub derived_assuming_build :Test(6){
    #diag "ASSUMING BUILD";
    my $cat = $derived_assuming;
    my @build_test = (
        [ { end => 5}, [1,2,3,4,5] ],
        [ { end => 1}, 1 ],
        [ { end => 0}, [] ],
            );
    for (@build_test) {
        my $object = $cat->build($_->[0]);
        $object->structure_ok($_->[1]);
        $object->is_of_category_ok( $cat );
    }
}

sub derived_assuming_is_instance :Test(9){
    #diag "ASSUMING IS INSTANCE";
    my $cat = $derived_assuming;
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

    @test_objects = ([2,3],
                     [4,6,5], [1,2,1,3],
                     [[2,2],3],
                         );
    for (@test_objects) {
        my $object = SObject->quik_create($_);
        my $bindings = $cat->is_instance($object);
        ok( !$bindings);
        if ($bindings) {
            # Something has gone wrong!
            # confess "Something went wrong!";
        }
    }


}


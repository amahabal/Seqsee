package SObject::Test;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use SObject;

sub create :Test(5) {
    my @test_set = 
        (
            [ [1],      [1]],
            [ [1,1],    [1,1]],
            [ [[1]],    [1]],
            [ [2, [3]], [2,3]],
            [ [2, [[[3]]]],   [2,3]],
                );
    for (@test_set) {
        cmp_deeply( SObject->create(@{$_->[0]})->get_structure(), $_->[1] );
    }
}

1;

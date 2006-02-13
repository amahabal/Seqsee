use blib;
use Test::Seqsee;

use SBuiltObj;

BEGIN { plan tests => 6; }

SUBOBJ_GIVEN_RANGE: {
    my $bo = SObject->create(2,4,6,8,10);
    my $count = 0;
    for my $pair (
        [ [ 0 .. 3 ], [ 2, 4, 6, 8 ] ],
        # [ [2], [6] ], Not when there is a single index!
        [ [2], 6],
        [ [],  [] ],
        [ [ 3, 4, 3, 1 ], [ 8, 10, 8, 4 ] ],
            )
        {
            $count++;
            my $so = $bo->get_subobj_given_range( $pair->[0] );
            if (ref($so) eq "ARRAY") {
                cmp_deeply( [map { $_->get_structure() } @$so],
                            $pair->[1], 
                            "subobj given range @{$pair->[0]}: deep comp" );
            } else {
                cmp_deeply( $so->get_structure,
                            $pair->[1], 
                            "subobj given range @{$pair->[0]}: deep comp" );
                
            }
  }
OUT_OF_RANGE: {
    dies_ok { $bo->get_subobj_given_range( [7] ) };
    dies_ok { $bo->get_subobj_given_range( [ 1, 7 ] ) };
  }
}

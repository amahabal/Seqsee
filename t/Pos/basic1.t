use lib 'genlib';
use Test::Seqsee;
BEGIN { plan tests => 23; }

# use Smart::Comments;

BEGIN {
    use_ok("SPos");
}

my $cat_asc = $S::ASCENDING;
my $cat_dsc = $S::DESCENDING;
my $cat_mnt = $S::MOUNTAIN;

my $bo1 = $cat_asc->build( { start => 5, end => 8 } );
$bo1->structure_ok( [ 5, 6, 7, 8 ] );

my $bo2      = $cat_dsc->build( { start => 9, end  => 1 } );
my $bo3      = $cat_mnt->build( { foot  => 3, peak => 6 } );
my $bo_small = $cat_mnt->build( { foot  => 4, peak => 4 } );

my $pos_first = new SPos(1);
isa_ok( $pos_first, "SPos" );

my $pos_first_copy = new SPos(1);
is( $pos_first, $pos_first_copy, "memoized..." );

my $pos_last = new SPos(-1);
isa_ok( $pos_last, "SPos" );

my $pos_second = new SPos(2);
isa_ok( $pos_second, "SPos" );

my $pos_last_butone = new SPos(-2);
isa_ok( $pos_last_butone, "SPos" );

my $sub_object;

RANGE_GIVEN_POSITION: {
    my $range;
    $range = $pos_second->find_range($bo1);
    cmp_deeply( $range, [1], "second index okay" );
    $range = $pos_last->find_range($bo1);
    cmp_deeply( $range, [3], "last index okay" );
}

ASCENDING: {
    my $count = 0;
    for my $pair ( [ $pos_first, 5 ], [ $pos_second, 6 ], [ $pos_last_butone, 7 ],
        [ $pos_last, 8 ] )
    {
        ### $pair->[0]
        ### $bo1
        my @sub_objects = $bo1->get_at_position( $pair->[0] );
        ### [map { $_->get_mag() }@sub_objects ]
        ### $pair->[1]
        $count++;
        cmp_deeply(
            [ map { $_->get_structure } @sub_objects ],
            [ $pair->[1] ],
            "ascending 5 8, subobj test $count"
        );
    }
}

DESCENDING: {
    my $count = 0;
    for my $pair ( [ $pos_first, 9 ], [ $pos_second, 8 ], [ $pos_last_butone, 2 ],
        [ $pos_last, 1 ] )
    {
        my @sub_objects = $bo2->get_at_position( $pair->[0] );
        $count++;
        cmp_deeply(
            [ map { $_->get_structure } @sub_objects ],
            [ $pair->[1] ],
            "descending 9 1, subobj test $count"
        );
    }
}

MOUNTAIN: {
    my $count = 0;
    for my $pair ( [ $pos_first, 3 ], [ $pos_second, 4 ], [ $pos_last_butone, 4 ],
        [ $pos_last, 3 ] )
    {
        my @sub_objects = $bo3->get_at_position( $pair->[0] );
        $count++;
        cmp_deeply(
            [ map { $_->get_structure } @sub_objects ],
            [ $pair->[1] ],
            "mountain 3 6, subobj test $count"
        );
    }

    dies_ok { $bo_small->get_at_position($pos_second) };

    dies_ok { $bo_small->get_at_position($pos_last_butone) };

}
use blib;
use Test::Seqsee;
BEGIN { plan tests => 13; }

use SBuiltObj;

my $bo = SObject->create(1,2,3);
ok( $bo->has_structure_one_of( [ 1, 2, 3 ] ) );
$bo->structure_ok( [ 1, 2, 3 ] );

SKIP: {
    skip "semiflattens unimplemented!", 7;
    # XXX MORE TESTS NEEDED HERE
    my @list;
    my $bo2 = SObject->create( 1, [2,3], [4,5]);
    
    @list = map { SObject->create($_) }[ 1, [ 2, 3 ], [ 4, 5 ] ];
    ok $bo2->semiflattens_ok(@list);

    @list = map { SObject->create($_) } 1, [ 2, 3 ], 4, 5;
    ok $bo2->semiflattens_ok(@list);

    @list = map { SObject->create($_) } 1, 2, 3, 4, 5;
    ok $bo2->semiflattens_ok(@list);

    @list = map { SObject->create($_) } 1, 2, 3, 4, 5, 6;
    ok not $bo2->semiflattens_ok(@list);

    @list = map { SObject->create($_) } 1, 2, 3, 4, 6;
    ok not $bo2->semiflattens_ok(@list);

  TODO: {
        local $TODO = 'semiflatten should respect structure';
        @list = map { SObject->create($_) } 1, [ [ 2, 3 ], [ 4, 5 ] ];
        ok not $bo2->semiflattens_ok(@list);

        @list = map { SBuiltObj->new_deep($_) } 1, 2, [ 3, 4 ], 5;
        ok not $bo2->semiflattens_ok(@list);

    }
}

BLEARILY: {
  SKIP: {
        skip "structure_blearily_ok unimplemented", 4;

        my $bo = SInt->new( { mag => 3 });
        ok $bo->structure_blearily_ok( 3 );
        ok !$bo->structure_blearily_ok( [ 3 ] );
        
        $bo = SBuiltObj->new_deep( 3 );
        ok $bo->structure_blearily_ok( 3 );
        ok $bo->structure_blearily_ok( [ 3 ] );
    }
}

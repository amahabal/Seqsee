use blib;
use Test::Seqsee;
BEGIN { plan tests => 13; }

use SBuiltObj;

my $bo = new SBuiltObj( { items => [ 1, 2, 3 ] } );
ok( $bo->structure_is( [ 1, 2, 3 ] ) );
$bo->structure_ok( [ 1, 2, 3 ] );

# XXX MORE TESTS NEEDED HERE
my @list;
my $bo2 = new_deep SBuiltObj( [ 1, [ 2, 3 ], [ 4, 5 ] ] );

@list = map { SBuiltObj->new_deep($_) }[ 1, [ 2, 3 ], [ 4, 5 ] ];
ok $bo2->semiflattens_ok(@list);

@list = map { SBuiltObj->new_deep($_) } 1, [ 2, 3 ], 4, 5;
ok $bo2->semiflattens_ok(@list);

@list = map { SBuiltObj->new_deep($_) } 1, 2, 3, 4, 5;
ok $bo2->semiflattens_ok(@list);

@list = map { SBuiltObj->new_deep($_) } 1, 2, 3, 4, 5, 6;
ok not $bo2->semiflattens_ok(@list);

@list = map { SBuiltObj->new_deep($_) } 1, 2, 3, 4, 6;
ok not $bo2->semiflattens_ok(@list);

TODO: {
  local $TODO = 'semiflatten should respect structure';
  @list = map { SBuiltObj->new_deep($_) } 1, [ [ 2, 3 ], [ 4, 5 ] ];
  ok not $bo2->semiflattens_ok(@list);

  @list = map { SBuiltObj->new_deep($_) } 1, 2, [ 3, 4 ], 5;
  ok not $bo2->semiflattens_ok(@list);

}


BLEARILY: {
  my $bo = SInt->new( { mag => 3 });
  ok $bo->structure_blearily_ok( 3 );
  ok !$bo->structure_blearily_ok( [ 3 ] );

  $bo = SBuiltObj->new_deep( 3 );
  ok $bo->structure_blearily_ok( 3 );
  ok $bo->structure_blearily_ok( [ 3 ] );

}

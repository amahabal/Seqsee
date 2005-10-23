use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 6; }


my $mtn = $S::MOUNTAIN;
my $ascending = $S::ASCENDING;
my $descending = $S::DESCENDING;

{
  my $bo = SObject->create(1, 2, 3);
  my $bindings = $bo->describe_as($ascending);
  ok $bindings;

  my $bindings2 = $bo->describe_as($ascending);
  cmp_ok( $bindings, 'eq', $bindings2 );

  ok not( $bo->describe_as($descending));
}

{
  my $bo = SObject->quik_create([1, [2,2], 3]);
  my $bindings = $bo->describe_as($ascending);
  ok $bindings;

  my $bindings2 = $bo->describe_as($ascending);
  cmp_ok( $bindings, 'eq', $bindings2 );

  ok not( $bo->describe_as($descending));
}

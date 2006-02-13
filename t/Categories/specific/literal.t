use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;
BEGIN { plan tests => 8; }

my $cat_literal = $S::LITERAL;
my $double = $S::DOUBLE;

my $cat_123 = $cat_literal->build( { structure => [1, 2, 3] } );

my $cat_123_again = $cat_literal->build( { structure => [1, 2, 3]});
is $cat_123, $cat_123_again, "Memoized!";

my $instance = $cat_123->build({});
$instance->structure_ok([1, 2, 3]);

IS_INSTANCE: {
  my $bo = SObject->create(1, 2, 3);
  my $bindings = $cat_123->is_instance($bo);
  ok $bindings;

  $bo = SObject->quik_create([1, [2, 2], 3]);
  ## $bo
  ## $bo->get_structure
  $bindings = $cat_123->is_instance($bo);
  ok $bindings;
  cmp_ok($bindings->get_metonymy_mode(), 'eq', 1);
}

my $cat_1 = $cat_literal->build( { structure => [1] });
$cat_1->build({})->structure_ok( [1] );

{ 
  my $bindings = $cat_1->is_instance( SObject->create(1) );
  ok $bindings, "SInt can be instance of the category";

  $bindings = $cat_1->is_instance( SObject->create(2));
  ok !$bindings;
  
}

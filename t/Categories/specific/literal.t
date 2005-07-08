use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 9; }

my $cat_literal = $S::literal;
my $double = $S::double;

my $cat_123 = $cat_literal->build( { structure => [1, 2, 3] } );

my $cat_123_again = $cat_literal->build( { structure => [1, 2, 3]});
is $cat_123, $cat_123_again, "Memoized!";

my $instance = $cat_123->build({});
$instance->structure_ok([1, 2, 3]);

IS_INSTANCE: {
  my $bo = SBuiltObj->new_deep(1, 2, 3);
  my $bindings = $cat_123->is_instance($bo);
  ok $bindings;

  $bo = SBuiltObj->new_deep(1, [2, 2], 3);
  $bo->seek_blemishes([$double]);
  $bindings = $cat_123->is_instance($bo);
  ok $bindings;
  $bindings->where_ok([1]);
  
}

my $cat_1 = $cat_literal->build( { structure => 1 });
$cat_1->build({})->structure_ok( 1 );

{ 
  my $bindings = $cat_1->is_instance( SInt->new( { mag => 1 }));
  ok $bindings, "SInt can be instance of the category";

  $bindings = $cat_1->is_instance( SInt->new( { mag => 2 }));
  ok !$bindings;
  
  $bindings = $cat_1->is_instance( SBuiltObj->new_deep(1));
  ok $bindings;


}

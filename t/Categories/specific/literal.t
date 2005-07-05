use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

my $cat_literal = $S::literal;
my $double = $S::double;

my $cat_123 = $cat_literal->build( { structure => [1, 2, 3] } );

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

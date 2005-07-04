use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 4; }

use SCat;
use SCat::literal;

use SBuiltObj;
use SBlemish::double;

my $cat_literal = $SCat::literal::literal;
my $double = $SBlemish::double::double;

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

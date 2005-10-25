use strict;
use blib;
use Test::Seqsee;
use Test::Base;
use Test::Seqsee::filters;

plan tests => scalar(blocks());

filters {
  construct => [qw{ lines chomp trim Sconstruct }],
    build => [qw{ lines chomp trim Sbuild }],
    mtl => [qw{lines trim}],
};

SKIP: {
    skip "command language not yet implemented", 11;
    construct_and_commands();
}
__END__

===
--- build
literal structure => [1, 2, 3]
! $S::cat_123 = $Object

--- mtl
isa SCat

===
--- build
literal structure => [1, 2, 3]
--- mtl
self $S::cat_123

===
--- build
cat_123
--- mtl
.get_structure, [1, 2, 3]

===
--- construct
[1, 2, 3]
is_instance cat_123
--- mtl
isa SBindings

===
--- construct
[1, 2, 3]
blemish_at ("double", 2)
is_instance cat_123
--- mtl
isa SBindings
.get_where(), [1]


===
--- build
literal structure => 1
! $S::cat_1 = $Object
--- mtl
isa SCat

===
--- build
cat_1
--- mtl
.get_structure() 1

===
--- construct
1
is_instance cat_1
--- mtl
isa SBindings

===
--- construct
2
is_instance cat_1
--- mtl
is_undef

===
--- construct
[1]
is_instance cat_1
--- mtl
isa SBindings

===
--- construct
1
blemish double
is_instance cat_1
--- mtl
isa SBindings

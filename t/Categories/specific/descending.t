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

construct_and_commands();

__END__

===
--- build
descending start => 5, end => 2
--- mtl
.get_structure, [5, 4, 3, 2]

===
--- build
descending start => 2, end => 2
--- mtl
.get_structure, [2]

===
--- build
descending start => 1, end => 2
--- mtl
.get_structure, []

===
--- construct
[4, 3, 2]
is_instance descending

--- mtl
isa SBindings
.{start}, 4
.{end},   2

===
--- construct
[2]
is_instance descending
--- mtl
.{start}, 2
.{end},   2

===
--- construct
[2, 4, 5]
is_instance descending
--- mtl
is_undef

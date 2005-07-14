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
literal structure => [1, 1]
! $S::cat_11 = $Object
--- mtl
isa SCat

===
--- construct
[ [3, 3], [1, 1], [4, 7] ]
blemish_at ("double", SPos->new_the($S::cat_11))
--- mtl
.get_structure, [ [3, 3], [ [1,1], [1,1] ], [4, 7] ]

===
--- build
ascending start => 2, end => 4
! $::bo_asc = $Object
--- mtl

===
--- build
mountain foot => 6, peak => 8
! $::bo_mtn = $Object
--- mtl

===
--- construct
[ $::bo_asc, 5, 6, $::bo_mtn]
blemish_at ("double", SPos->new_the( $S::mountain ))
--- mtl
.get_structure, [ [2, 3, 4], 5, 6, [[6, 7, 8, 7, 6], [6, 7, 8, 7, 6]]]

===
--- construct
[ $::bo_asc, 5, 6, $::bo_mtn]
blemish_at ("double", SPos->new_the( $S::ascending ))
--- mtl
.get_structure, [ [[2, 3, 4], [2, 3, 4]], 5, 6, [6, 7, 8, 7, 6]]


=== 
--- build
literal structure => 2
! $S::cat_2 = $Object
--- mtl
isa SCat

===
--- construct
[2, 3, 4, 5]
blemish_at ("double", SPos->new_the( $S::cat_2 ))
--- mtl
.get_structure, [ [2, 2], 3, 4, 5 ]

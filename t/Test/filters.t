use strict;
use blib;
use Test::Seqsee;
use Test::Base;
use Test::Seqsee::filters;

plan tests => 6 + scalar(blocks());

*my_comapre_deep = *Test::Seqsee::filters::my_comapre_deep;

ok my_comapre_deep(3, 3);
ok !my_comapre_deep(3, 4);
ok my_comapre_deep([3], [3]);
ok my_comapre_deep([3, 4, [5, 6]], [3, 4, [5, 6]]);
ok my_comapre_deep([{a => [3]}],
		   [{a => [3]}]
		  );
ok !my_comapre_deep([{a => [3]}],
		   [{a => [3], b => 4}]
		  );

filters {
  construct => [qw{ lines chomp trim Sconstruct }],
    build => [qw{ lines chomp trim Sbuild }],
    mtl => [qw{lines trim}],
};

SKIP: {
    skip("Have not converted the test language yet", 11);
}
#construct_and_commands();

__END__

===
--- construct
 1
--- mtl
isa SInt
.get_mag, 1
.get_structure, 1

===
--- construct
[1]
--- mtl
isa SBuiltObj
.get_structure, [1]

===
--- construct
[1, 2]
--- mtl
isa SBuiltObj
.get_structure, [1, 2]

=== 
--- construct
[1, [2, 3]]
--- mtl
isa SBuiltObj
.get_structure, [1, [2, 3]]


===
--- construct
1
blemish double
--- mtl
isa SBuiltObj
.get_structure, [1, 1]

===
--- construct
1
blemish double
blemish triple
--- mtl
.get_structure, [ [1, 1], [1, 1], [1, 1] ]


===
--- construct
[1, 2]
blemish double
--- mtl
.get_structure, [[1, 2], [1, 2]]

===
--- construct
[1, 2]
blemish_at ("double", 1)
--- mtl
.get_structure, [ [1, 1], 2 ]


===
--- construct
[[1, 2, 1] , [2, 3]]
blemish_at ("double", SPos->new_the($S::mountain));
--- mtl
.get_structure, [ [ [1,2,1], [1,2,1] ], [2, 3]]

===
--- build
mountain foot => 2, peak => 4
blemish_at ("double", "peak")
--- mtl
.get_structure, [2, 3, [4, 4], 3, 2]

===
--- build
mountain foot => 2, peak => 4
is_instance mountain
--- mtl
isa SBindings


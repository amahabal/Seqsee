use strict;
use blib;
use Test::Seqsee;

use Test::Base;
use Test::Seqsee::filters;

plan tests => scalar(blocks());

filters {
  string_build => [qw{lines chomp trim Sfrom_string}],
    mtl => [qw{lines trim}],
};

SKIP: {
    skip( "TODO!", 5);
    construct_and_commands();

}

__END__

===
--- string_build
1 2 3 4
--- mtl
.get_structure, [1, 2, 3, 4]

===
--- string_build
1, 2, 3 4
--- mtl
.get_structure, [1, 2, 3, 4]

===
--- string_build
(1, 2), 3 4
--- mtl
.get_structure, [ [1, 2], 3, 4]

===
--- string_build
(1 2) 3 4
--- mtl
.get_structure, [ [1, 2], 3, 4]

===
--- string_build
1, 2 (3, (4 5 ( 6 7))) 8
--- mtl
.get_structure, [1, 2, [3, [4, 5, [6, 7]]], 8]


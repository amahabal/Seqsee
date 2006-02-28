use strict;
use blib;
use Test::Seqsee;
use Test::Base;
use Test::Seqsee::filters;

use SOddman;
use SOddman::Test;

plan tests => scalar(  blocks() );



filters { oddman => [qw{lines chomp oddman}],
	    expected => [qw{chomp}],
	};

run_is;

__END__

=== ascending
--- oddman
1 2 3
8 7 6
1 2 3 4
5 6
--- expected
ascending

===
--- oddman
1 2 3
3 4 5
1 2
1 2 3 4 5 6
--- expected
ascending, with  start => 1

===
--- oddman
1 2 3 4 3 2 1
1 2 1
3 4 3
4
--- expected
mountain, with  peak => 4

===
--- oddman
1 1 2 3
1 2 3 3 3
2 3 4
1 1 2 3 3
--- expected
ascending, with  end => 3, start => 1

===
--- oddman
1 1 2 3
7 7 8 9
5 5 6 7 8 9
4 5 5 6
--- expected
ascending containing a blemish at position 1

===
--- SKIP Want this to be TODO, really
--- oddman
1 2 3 3 3 4
1 1 1 2 3 4 5 6
3 4 5 4 4 4 3
2 3 4 5 5 6 5 4 3 2

--- expected
triple

===
--- oddman
1 2 3 3 4
8 9 10 10 11
3 4 5 6 7 8 9 9 10
5 6 6 7 8 9
--- expected
ascending containing a blemish at position -2

===
--- oddman
1 2 3 3 4
3 3 4 5 6 7 8
2 3 4 4 5 6
-1 0 1 2 3 3 4 5 6 7 8
--- expected
ascending containing a blemish at position the 3

===
--- oddman
1 1 2 3 3
8 9 10 10 11 12 12 13
4 5 5 6
7 7 8 8 9
--- expected
ascending containing 2 blemish(es)



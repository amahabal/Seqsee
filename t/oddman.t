use strict;
use blib;
use Test::Seqsee;
use Test::Base;
use Test::Seqsee::filters;

BEGIN { plan tests => 10; }



filters { oddman => [qw{lines chomp oddman}]};

for my $block (blocks()) {
  # print $block, "Name= ", $block->name,"\n";
  my $oddman = $block->{oddman};
  print "oddman evaluated to $oddman\n";
  #if (ref $oddman eq "ARRAY") {
  #  print "@$oddman\n";
  #}

}

__END__

=== ascending
--- oddman
1 2 3
8 7 6
1 2 3 4
5 6
--- expected
5 6
ascending

===
--- oddman
1 2 3
3 4 5
1 2
1 2 3 4 5 6
--- expected
3 4 5
ascending starting with 1

===
--- oddman
1 2 3 4 3 2 1
1 2 1
3 4 3
4
--- expected
1 2 1
mountain peaking with 4

===
--- oddman
1 1 2 3
1 2 3 3 3
1 2 3 4
1 1 2 3 3
--- expected
1 2 3 4
1 2 3

===
--- oddman
1 1 2 3
7 7 8 9
5 5 6 7 6 5
4 5 5 6
--- expected
4 5 5 6
blemished at position '1'

===
--- oddman
1 2 3 3 3 4
1 1 1 2 3 4 5 6
3 4 5 4 4 4 3
2 3 4 5 5 6

--- expected
2 3 4 5 5 6
triple

===
--- oddman
1 2 3 3 4
8 9 10 10 11
3 4 5 6 7 8 9 9 10
5 6 6 7 8 9
--- expected
5 6 6 7 8 9
blemished at position '-2'

===
--- oddman
1 2 3 3 4
3 3 4 5 6 7 8
2 3 4 4 5 6
1 2 3 3 4 5 6 7 8
--- expected
2 3 4 4 5 6
blemished at position 'the 3'

===
--- oddman
1 1 2 3 3
8 9 10 10 11 12 12 13
4 5 5 6
7 7 8 8 9
--- expected
4 5 5 6
blemished multiple times


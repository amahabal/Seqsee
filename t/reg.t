use strict;
use blib;
use Test::Seqsee;
plan tests => 2; 

cmp_ok( RegTestHelper({seq => [qw(1 2 3 4)],
                       continuation => [qw(5 6 7 8 9 10 11 12 13 14 15 16)],
                       max_false => 3,
                       max_steps => 10000, 
                       min_extension => 2}), 'eq', 'GotIt', );

cmp_ok( RegTestHelper({seq => [qw(1 2 3 4)],
                       continuation => [qw(9)],
                       max_false => 0,
                       max_steps => 10000, 
                       min_extension => 1}), 'eq', 'TooManyFalseQueries', );

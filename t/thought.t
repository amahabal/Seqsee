use strict;
use blib;
use Test::Seqsee;
plan tests => 12; 

## VERY SKETCHY!!

my $bo = SObject->create(2, 3, 4);
my $cat_ascending = $S::ASCENDING;
my $pos_second = SPos->new(2);

my $t1 = SThought->create($bo);
my $t2 = SThought->create($cat_ascending);
my $t3 = SThought->create($pos_second);

isa_ok $t1, "SThought";
isa_ok $t2, "SThought";
isa_ok $t3, "SThought";


for ($t1, $t2, $t3) {
    lives_ok { $_->get_fringe();} "lives: fringe ". ref( $_->get_core() ); 
}

for ($t1, $t2, $t3) {
    lives_ok { $_->get_extended_fringe();} 
        "lives: extended fringe ". ref( $_->get_core() ); 
}

for ($t1, $t2, $t3) {
    lives_ok { $_->get_actions();} "lives: actions ". ref( $_->get_core() ); 
}

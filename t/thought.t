use strict;
use blib;
use Test::Seqsee;
plan tests => 16; 


my $bo = SBuiltObj->new_deep(2, 3, 4);
my $cat_ascending = $S::ascending;
my $pos_second = SPos->new(2);
my $blemishtype_doubled = $S::double;

my $t1 = SThought->new( { core => $bo });
my $t2 = SThought->new( { core => $cat_ascending });
my $t3 = SThought->new( { core => $pos_second });
my $t4 = SThought->new( { core => $blemishtype_doubled });

isa_ok $t1, "SThought";
isa_ok $t2, "SThought";
isa_ok $t3, "SThought";
isa_ok $t4, "SThought";


for ($t1, $t2, $t3, $t4) {
    lives_ok { $_->get_fringe();} "lives: fringe ". ref( $_->get_core() ); 
}

for ($t1, $t2, $t3, $t4) {
    lives_ok { $_->get_extended_fringe();} 
        "lives: extended fringe ". ref( $_->get_core() ); 
}

for ($t1, $t2, $t3, $t4) {
    lives_ok { $_->get_actions();} "lives: actions ". ref( $_->get_core() ); 
}

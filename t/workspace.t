use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 18; }

#use MyFilter;

use SWorkspace;
use SElement;

SWorkspace->setup( 1, 2, 3, 4 );
is $SWorkspace::elements_count, 4;
isa_ok $SWorkspace::elements[2], "SElement";
isa_ok $SWorkspace::elements[2], "SInt";
is $SWorkspace::elements[2]->get_mag(), 3;
is $SWorkspace::elements[2]->get_left_edge,  2;
is $SWorkspace::elements[2]->get_right_edge, 2;

SWorkspace->insert_elements( 5, 6 );
is $SWorkspace::elements_count, 6;
isa_ok $SWorkspace::elements[5], "SElement";
isa_ok $SWorkspace::elements[5], "SInt";
is $SWorkspace::elements[5]->get_mag(), 6;
is $SWorkspace::elements[5]->get_left_edge,  5;
is $SWorkspace::elements[5]->get_right_edge, 5;

SWorkspace->setup( 8, 9, 10, 11 );
is $SWorkspace::elements_count, 4;
isa_ok $SWorkspace::elements[2], "SElement";
isa_ok $SWorkspace::elements[2], "SInt";
is $SWorkspace::elements[2]->get_mag(), 10;
is $SWorkspace::elements[2]->get_left_edge,  2;
is $SWorkspace::elements[2]->get_right_edge, 2;

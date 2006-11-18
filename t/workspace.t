use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 22; }

SWorkspace->init( { seq => [ 1, 2, 3, 4 ] } );
is $SWorkspace::elements_count, 4;
isa_ok $SWorkspace::elements[2], "SElement";
is $SWorkspace::elements[2]->get_mag(), 3;
is $SWorkspace::elements[2]->get_left_edge,  2;
is $SWorkspace::elements[2]->get_right_edge, 2;

SWorkspace->insert_elements( 5, 6 );
is $SWorkspace::elements_count, 6;
isa_ok $SWorkspace::elements[5], "SElement";

# isa_ok $SWorkspace::elements[5], "SInt";
is $SWorkspace::elements[5]->get_mag(), 6;
is $SWorkspace::elements[5]->get_left_edge,  5;
is $SWorkspace::elements[5]->get_right_edge, 5;

SWorkspace->init( { seq => [ 8, 9, 10, 11 ] } );
is $SWorkspace::elements_count, 4;
isa_ok $SWorkspace::elements[2], "SElement";

# isa_ok $SWorkspace::elements[2], "SInt";
is $SWorkspace::elements[2]->get_mag(), 10;
is $SWorkspace::elements[2]->get_left_edge,  2;
is $SWorkspace::elements[2]->get_right_edge, 2;

my $group = SAnchored->create(@SWorkspace::elements[0,1,2]);
my $group2 = SAnchored->create(@SWorkspace::elements[0,1,2]);
lives_ok {SWorkspace->add_group($group)};
lives_ok {SWorkspace->add_group($group)} "Not a contradiction to add same group";
dies_ok  {SWorkspace->add_group($group2)} "But not okay to add another conflicting group!";

my $small_group = SAnchored->create(@SWorkspace::elements[0,1]);
dies_ok {SWorkspace->add_group($small_group)} "This is spanned by another, existing group";

my $other_group = SAnchored->create(@SWorkspace::elements[2,3]);

is(scalar($other_group->Extend($SWorkspace::elements[1], 0)), 0, "No conflicts!");
$other_group->structure_ok([9, 10, 11]);

is(scalar($other_group->Extend($SWorkspace::elements[0], 0)), 1, "Now there is overlap, so conflict");

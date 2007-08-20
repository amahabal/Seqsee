use strict;
use lib 'genlib';
use Test::Seqsee;
BEGIN { plan tests => 29; }

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

my $group  = SAnchored->create( @SWorkspace::elements[ 0, 1, 2 ] );
my $group2 = SAnchored->create( @SWorkspace::elements[ 0, 1, 2 ] );
ok( SWorkspace->add_group($group) );
ok( !SWorkspace->add_group($group),  "Adding another copy of same group returns false" );
ok( !SWorkspace->add_group($group2), "Adding a different equivalent group also false" );

my $small_group = SAnchored->create( @SWorkspace::elements[ 0, 1 ] );
ok( ( !SWorkspace->add_group($small_group) or !exists( $SWorkspace::groups{$group} ) ),
    "This is spanned by another, existing group. Only one lives!" );

# Make sure 012 is the group that exists...
delete $SWorkspace::groups{$small_group};
SWorkspace->add_group($group);

my $other_group = SAnchored->create( @SWorkspace::elements[ 2, 3 ] );

is( $other_group->Extend( $SWorkspace::elements[1], 0 ), 1, "No conflicts!" );
$other_group->structure_ok( [ 9, 10, 11 ] );

ok( (   $other_group->Extend( $SWorkspace::elements[0], 0 )
            or !exists( $SWorkspace::elements{$group} )
    ),
    "Existing group deleted, or extension failed!"
);

SWorkspace->init( { seq => [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ] } );

sub test_conflict {
    my ( $gp1_indices_ref, $gp2_indices_ref, $in_conflict_p, $msg ) = @_;
    my $gp1 = create_group_from_indices($gp1_indices_ref);
    my $gp2 = create_group_from_indices($gp2_indices_ref);
    cmp_ok( SWorkspace->AreGroupsInConflict( $gp1, $gp2 ), 'eq', $in_conflict_p, $msg );
}

sub create_group_from_indices {
    my ($indices) = @_;
    if ( ref $indices ) {
        return SAnchored->create( map { create_group_from_indices($_) } @$indices );
    }
    else {
        return $SWorkspace::elements[$indices];
    }
}

use constant CONFLICT    => 1;
use constant NO_CONFLICT => 0;

test_conflict( 0, 1, NO_CONFLICT, "non-overlap" );
test_conflict( 0, 0, CONFLICT );
test_conflict( 0, [ 0, 1 ], NO_CONFLICT );
test_conflict( [ 0, 1 ], [ 0, 1, 2 ], CONFLICT );
test_conflict( [ 0, 1 ], [ [ 0, 1 ], 2 ], NO_CONFLICT );
test_conflict( [ 2, 3 ], [ [ 1, 2 ], [ 2, 3 ] ], NO_CONFLICT );
test_conflict( [ 0, 1, 2 ], [ 0, 1, 2 ], CONFLICT );

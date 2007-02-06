use strict;
use blib;
use Test::Seqsee;
use File::Temp qw( tempfile );
use Class::Multimethods qw{find_reln};
use Smart::Comments;
use SLTM;

multimethod 'plonk_into_place';

plan tests => 22;

sub DumpAndReload {
    my $fh = new File::Temp( TEMPLATE => 'XXXXX', SUFFIX => '.ltm', UNLINK => 0 );
    my $filename = $fh->filename;
    SLTM->Dump($fh);    # That also closes the filehandle

    SLTM->Clear();

    SLTM->Load($filename);
}

SLTM->Clear();
is( SLTM->GetNodeCount(), 0 );

my $node = SLTM::GetMemoryIndex( $S::LITERAL->build( { structure => 1 } ) );
is( SLTM->GetNodeCount(), 1, "SNode Automatically added to LTM" );

my $node2 = SLTM::GetMemoryIndex( $S::LITERAL->build( { structure => 1 } ) );
is $node, $node2;
is( SLTM->GetNodeCount(), 1, "Duplicate node not added" );

DumpAndReload();
is( SLTM->GetNodeCount(), 1, "Nodes correctly present on reloading" );

my $node3 = SLTM::GetMemoryIndex( $S::LITERAL->build( { structure => 1 } ) );
is( SLTM->GetNodeCount(), 1, "Retrieved correctly from loaded memory" );

my $node4 = SLTM::GetMemoryIndex( $S::LITERAL->build( { structure => 2 } ) );
is( SLTM->GetNodeCount(), 2, "Different Nodes are different" );

lives_ok {
    SLTM::GetMemoryIndex($S::ASCENDING);
    SLTM::GetMemoryIndex( SElement->create( 2, 0 ) );    # Creates a platonic node
};

is( SLTM->GetNodeCount(), 4, "Different Nodes are different" );

my $node5 = SLTM::GetMemoryIndex($S::ASCENDING);
is $node5, 3, "Core correctly accessible for categories";

DumpAndReload();
is( SLTM->GetNodeCount(), 4, "count okay after reload" );

my $node6 = SLTM::GetMemoryIndex($S::ASCENDING);
is( SLTM->GetNodeCount(), 4, "S::Ascending remembered" );
is $node6, 3;

my $node7 = SLTM::GetMemoryIndex( SElement->create( 2, 7 ) );
is( SLTM->GetNodeCount(), 4, "SElement recalls the correct platonic" );

# Connecting it to objects in workspace.
SWorkspace->init( { seq => [qw( 1 1 2 3 1 2 2 3 4 1 2 3 3 4 5)] } );
my @groups = (
    plonk_into_place( 0, $DIR::RIGHT, SObject->QuickCreate( [ [ 1, 1 ], 2, 3 ], $S::ASCENDING ) ),
    plonk_into_place(
        4, $DIR::RIGHT, SObject->QuickCreate( [ 1, [ 2, 2 ], 3, 4 ], $S::ASCENDING )
    ),
    plonk_into_place(
        9, $DIR::RIGHT, SObject->QuickCreate( [ 1, 2, [ 3, 3 ], 4, 5 ], $S::ASCENDING )
    ),
);

is $node7, SLTM::GetMemoryIndex( $SWorkspace::elements[2] ), "Platonic recalled";
is $node7, SLTM::GetMemoryIndex( $SWorkspace::elements[5] ), "Platonic recalled";
cmp_ok $node7, 'ne', SLTM::GetMemoryIndex( $SWorkspace::elements[4] );

my $WSO_ra = find_reln( $SWorkspace::elements[0], $SWorkspace::elements[1] );
$WSO_ra->insert();
my $node8 = SLTM::GetMemoryIndex($WSO_ra);
my $WSO_rb = find_reln( $SWorkspace::elements[5], $SWorkspace::elements[6] );
$WSO_rb->insert();
is $node8, SLTM::GetMemoryIndex($WSO_rb), "Similar relations properly extracted";

my $WSO_rc = find_reln( @groups[0,1] ) or confess "No relation found!";
$WSO_rc->insert();
my $node9 = SLTM::GetMemoryIndex($WSO_rc);

my $WSO_rd = find_reln( @groups[1,2] ) or confess "No relation found!";
$WSO_rd->insert();
is $node9, SLTM::GetMemoryIndex($WSO_rd);

my $count = SLTM->GetNodeCount();
DumpAndReload();
is( SLTM->GetNodeCount(), $count, "Reloaded fine" );
is $node9, SLTM::GetMemoryIndex($WSO_rd), "And reloaded relation is properly revivified!";
is $node7, SLTM::GetMemoryIndex( $SWorkspace::elements[2] ), "and so is a platonic node";

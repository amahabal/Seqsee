use strict;
use blib;
use Test::Seqsee;
use File::Temp qw( tempfile );
use Class::Multimethods qw{GetExactFromMemory find_reln};

use SLTM;

plan tests => 23;

sub DumpAndReload {
    my $fh = new File::Temp( TEMPLATE => 'XXXXX', SUFFIX => '.ltm', UNLINK => 0 );
    my $filename = $fh->filename;
    SLTM->Dump($fh);    # That also closes the filehandle

    SLTM->Clear();

    SLTM->Load($filename);
}

SLTM->Clear();
is( SLTM->GetNodeCount(), 0 );

my $node = GetExactFromMemory( $S::LITERAL->build( { structure => 1 } ) );
is( SLTM->GetNodeCount(), 1, "SNode Automatically added to LTM" );

my $node2 = GetExactFromMemory( $S::LITERAL->build( { structure => 1 } ) );
is $node, $node2;
is( SLTM->GetNodeCount(), 1, "Duplicate node not added" );

DumpAndReload();
is( SLTM->GetNodeCount(), 1, "Nodes correctly present on reloading" );

my $node3 = GetExactFromMemory( $S::LITERAL->build( { structure => 1 } ) );
is( SLTM->GetNodeCount(), 1, "Retrieved correctly from loaded memory" );

my $node4 = GetExactFromMemory( $S::LITERAL->build( { structure => 2 } ) );
is( SLTM->GetNodeCount(), 2, "Different Nodes are different" );

lives_ok {
    GetExactFromMemory($S::ASCENDING);

    # May not be directly accessible later, but could still play a activation passing role
    GetExactFromMemory( SElement->create( 2, 0 ) );    # Creates a platonic node
};

is( SLTM->GetNodeCount(), 4, "Different Nodes are different" );

my $node5 = GetExactFromMemory($S::ASCENDING);
is $node5->get_core(), $S::ASCENDING, "Core correctly accessible for categories";

DumpAndReload();
is( SLTM->GetNodeCount(), 4, "count okay after reload" );

my $node6 = GetExactFromMemory($S::ASCENDING);
is( SLTM->GetNodeCount(), 4, "S::Ascending remembered" );
is $node6->get_core(), $S::ASCENDING, "Core correctly accessible for categories after reload";

my $node7 = GetExactFromMemory( SElement->create( 2, 0 ) );
is( SLTM->GetNodeCount(), 4, "SElement recalls the correct platonic" );

# Connecting it to objects in workspace.
SWorkspace->init( { seq => [qw( 1 1 2 3 1 2 2 3 4 1 2 3 3 4 5)] } );
is $node7, GetExactFromMemory( $SWorkspace::elements[2] ), "Platonic recalled";
is $node7, GetExactFromMemory( $SWorkspace::elements[5] ), "Platonic recalled";
cmp_ok $node7, 'ne', GetExactFromMemory( $SWorkspace::elements[4] ), "Platonic recalled";

my $WSO_ra = find_reln( $SWorkspace::elements[0], $SWorkspace::elements[1] );
$WSO_ra->insert();
my $node8 = GetExactFromMemory($WSO_ra);
my $WSO_rb = find_reln( $SWorkspace::elements[5], $SWorkspace::elements[6] );
$WSO_rb->insert();
is $node8, GetExactFromMemory($WSO_rb), "Similar relations properly extracted";

my $WSO_ga = SAnchored->create( $SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);
$WSO_ga->describe_as($S::SAMENESS);
$WSO_ga->annotate_with_metonym( $S::SAMENESS, "each" );
$WSO_ga->set_metonym_activeness(1);

my $WSO_gb = SAnchored->create( $WSO_ga, $SWorkspace::elements[2], $SWorkspace::elements[3], );
SWorkspace->add_group($WSO_gb);
$WSO_gb->describe_as($S::ASCENDING) or confess "Describing as ascending failed";
$WSO_gb->tell_forward_story($S::ASCENDING);

my $WSO_gc = SAnchored->create( $SWorkspace::elements[5], $SWorkspace::elements[6], );
SWorkspace->add_group($WSO_gc);
$WSO_gc->describe_as($S::SAMENESS);
$WSO_gc->annotate_with_metonym( $S::SAMENESS, "each" );
$WSO_gc->set_metonym_activeness(1);

my $WSO_gd = SAnchored->create(
    $SWorkspace::elements[4],
    $WSO_gc,
    $SWorkspace::elements[7],
    $SWorkspace::elements[8]
);
SWorkspace->add_group($WSO_gd);
$WSO_gd->describe_as($S::ASCENDING) or confess "Describing as ascending failed";
$WSO_gd->tell_forward_story($S::ASCENDING);

my $WSO_ge = SAnchored->create( $SWorkspace::elements[11], $SWorkspace::elements[12], );
SWorkspace->add_group($WSO_ge);
$WSO_ge->describe_as($S::SAMENESS);
$WSO_ge->annotate_with_metonym( $S::SAMENESS, "each" );
$WSO_ge->set_metonym_activeness(1);

my $WSO_gf = SAnchored->create($SWorkspace::elements[9], $SWorkspace::elements[10], $WSO_ge, $SWorkspace::elements[13], $SWorkspace::elements[14], );
SWorkspace->add_group($WSO_gf);
$WSO_gf->describe_as($S::ASCENDING) or confess "Describing as ascending failed";
$WSO_gf->tell_forward_story($S::ASCENDING);

my $WSO_rc = find_reln( $WSO_gb, $WSO_gd ) or confess "No relation found!";
$WSO_rc->insert();
my $node9 = GetExactFromMemory($WSO_rc);

my $WSO_rd = find_reln($WSO_gd, $WSO_gf)  or confess "No relation found!";;
$WSO_rd->insert();
is $node9, GetExactFromMemory($WSO_rd);

is( SLTM->GetNodeCount(), 7, "Now has Categories, elements, relns of both types" );
DumpAndReload();
is( SLTM->GetNodeCount(), 7, "Reloaded fine" );
is $node9, GetExactFromMemory($WSO_rd), "And reloaded relation is properly revivified!";
is $node7, GetExactFromMemory( $SWorkspace::elements[2] ), "and so is a platonic node";

use strict;
use lib 'genlib';
use Test::Seqsee;
use Smart::Comments;
plan tests => 6; 

use Class::Multimethods qw(find_reln);
use Class::Multimethods qw(are_relns_compatible);
use Class::Multimethods qw(apply_reln);
use Class::Multimethods qw(plonk_into_place);

SWorkspace->init({seq => [qw( 1 8 10 2 7 10 3 6 10)]});

my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], $SWorkspace::elements[2], );
SWorkspace->add_group($WSO_ga);
my $WSO_gb = SAnchored->create($SWorkspace::elements[3], $SWorkspace::elements[4], $SWorkspace::elements[5], );
SWorkspace->add_group($WSO_gb);
#my $WSO_gc = SAnchored->create($SWorkspace::elements[6], $SWorkspace::elements[7], $SWorkspace::elements[8], );
#SWorkspace->add_group($WSO_gc);

my $cat = $S::AD_HOC->build({parts_count => 3});
ok( $WSO_ga->describe_as($cat) );
ok( $WSO_gb->describe_as($cat) );


## $WSO_ga, $WSO_gb

my $WSO_ra = find_reln($WSO_ga, $WSO_gb);
$WSO_ra->insert();
 
## $WSO_ra
my $next = apply_reln( $WSO_ra, $WSO_gb );
## $next
$next->structure_ok( [3, 6, 10]);
instance_of_cat_ok( $next, $cat );

SUtil::clear_all();

SWorkspace->init({seq => [qw( 1 8 10 1 2 7 10 1 2 3 6 10)]});

$WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], $SWorkspace::elements[2], );
SWorkspace->add_group($WSO_ga);
$SWorkspace::elements[0]->describe_as($S::ASCENDING);

my $WSO_gba = SAnchored->create($SWorkspace::elements[3], $SWorkspace::elements[4], );
SWorkspace->add_group($WSO_gba);
$WSO_gba->describe_as($S::ASCENDING);

$WSO_gb = SAnchored->create($WSO_gba, $SWorkspace::elements[5], $SWorkspace::elements[6]);
SWorkspace->add_group($WSO_gb);

my $WSO_gca = SAnchored->create($SWorkspace::elements[7], $SWorkspace::elements[8], $SWorkspace::elements[9], );
SWorkspace->add_group($WSO_gca);
$WSO_gca->describe_as($S::ASCENDING);
 

#$WSO_gc = SAnchored->create($WSO_gca, $SWorkspace::elements[10], $SWorkspace::elements[11] );
#SWorkspace->add_group($WSO_gc);

$cat = $S::AD_HOC->build({parts_count => 3});
$WSO_ga->describe_as($cat);
$WSO_gb->describe_as($cat);

$WSO_ra = find_reln($WSO_ga, $WSO_gb);
$WSO_ra->insert();
 
$next = apply_reln( $WSO_ra, $WSO_gb );
$next->structure_ok( [[1,2,3], 6, 10]);
instance_of_cat_ok( $next, $cat );



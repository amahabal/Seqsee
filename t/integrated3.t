use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;
plan tests => 30; 

use Class::Multimethods qw(find_reln);
use Class::Multimethods qw(are_relns_compatible);
use Class::Multimethods qw(apply_reln);
use Class::Multimethods qw(plonk_into_place);

SWorkspace->init({seq => [qw( 1 1 2 3 1 2 2 3)]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();

my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);
 
$WSO_ga->describe_as($S::SAMENESS);

dies_ok { $WSO_ga->SetMetonymActiveness(1);};

$WSO_ga->AnnotateWithMetonym( $S::SAMENESS, "each");
my $WSO_ma = $WSO_ga->get_metonym();
## $WSO_ma
isa_ok( $WSO_ma, "SMetonym");
ok( $WSO_ma->get_category() eq $S::SAMENESS, );
ok( $WSO_ma->get_name() eq "each", );
ok( UNIVERSAL::isa($WSO_ma->get_starred(), "SObject"), "isa SObject");
ok( UNIVERSAL::isa($WSO_ma->get_starred(), "SElement"), "isa SElement");
SUtil::compare_deep( $WSO_ma->get_starred()->get_structure, 1);
ok( $WSO_ma->get_unstarred() eq $WSO_ga, );
ok( not($WSO_ma->get_starred() eq $SWorkspace::elements[0]), "starred is brand new" );
ok( not($WSO_ma->get_starred() eq $SWorkspace::elements[1]), "starred is brand new");


ok( not($WSO_ga->get_metonym_activeness()), );
ok( not(find_reln($WSO_ga, $SWorkspace::elements[2])), );

lives_ok { $WSO_ga->SetMetonymActiveness(1);};

my $WSO_rb = find_reln($WSO_ga, $SWorkspace::elements[2]);
$WSO_rb->insert();
ok( $WSO_rb, );
isa_ok( $WSO_rb, "SReln::Simple");

my $WSO_rc = find_reln($SWorkspace::elements[2], $SWorkspace::elements[3]);
$WSO_rc->insert();

my $WSO_gb = SAnchored->create($WSO_ga, $SWorkspace::elements[2], $SWorkspace::elements[3], );
SWorkspace->add_group($WSO_gb);
$WSO_gb->describe_as($S::ASCENDING);
$WSO_gb->tell_forward_story($S::ASCENDING);

my $bindings = $WSO_gb->describe_as($S::ASCENDING);
ok( $bindings, );
my $ref = $bindings->get_bindings_ref;
ok( $ref->{start} == 1, );
ok( $ref->{end} == 3, );
ok( $bindings->get_metonymy_mode() eq METO_MODE::SINGLE(), );
## Posmode test
ok( $bindings->get_position_mode() eq POS_MODE::FORWARD(), );
ok( $bindings->get_position()->get_index == 1, );

## $bindings->get_position()
my $meto_type = $bindings->get_metonymy_type;
isa_ok( $meto_type, "SMetonymType");


my $WSO_gd = SAnchored->create($SWorkspace::elements[5], $SWorkspace::elements[6], );
SWorkspace->add_group($WSO_gd);
$WSO_gd->describe_as($S::SAMENESS);
$WSO_gd->AnnotateWithMetonym($S::SAMENESS, "each");
$WSO_gd->SetMetonymActiveness(1);

my $WSO_ge = SAnchored->create($SWorkspace::elements[4], $WSO_gd, $SWorkspace::elements[7], );
SWorkspace->add_group($WSO_ge);
$WSO_ge->describe_as($S::ASCENDING);
$WSO_ge->tell_forward_story($S::ASCENDING);

my $WSO_rm = find_reln($WSO_gb, $WSO_ge);
$WSO_rm->insert();
isa_ok($WSO_rm, "SReln::Compound");
ok( $WSO_rm->get_type()->get_base_category() eq $S::ASCENDING, );
ok( $WSO_rm->get_type()->get_base_meto_mode() eq METO_MODE::SINGLE(), );
ok( $WSO_rm->get_type()->get_base_pos_mode() eq POS_MODE::FORWARD(), );

my $WSO_gn = apply_reln( $WSO_rm, $WSO_ge );
ok( $WSO_gn, );
ok( $WSO_gn->get_direction() eq DIR::RIGHT(), );


$WSO_gn->structure_ok( [1,2,[3,3]]);
$bindings = $WSO_gn->GetBindingForCategory($S::ASCENDING);
ok( $bindings->get_metonymy_mode() eq METO_MODE::SINGLE(), );
## here...
ok( $WSO_gn->[2]->GetBindingForCategory($S::SAMENESS), );

 









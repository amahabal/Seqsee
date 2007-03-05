use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;
plan tests => 36; 

use Class::Multimethods qw(find_reln);
use Class::Multimethods qw(are_relns_compatible);
use Class::Multimethods qw(apply_reln);
use Class::Multimethods qw(plonk_into_place);


SWorkspace->init({seq => [qw( 1 2 3 6 7 9 9)]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();
 
ok( UNIVERSAL::isa($WSO_ra, "SReln") );
ok( exists $SWorkspace::relations{$WSO_ra}, );
ok( UNIVERSAL::isa($SWorkspace::elements[0], "SElement")  );
ok( $SWorkspace::elements[0]->get_relation($SWorkspace::elements[1]) eq $WSO_ra, );
ok( $SWorkspace::elements[1]->get_relation($SWorkspace::elements[0]) eq $WSO_ra, );
ok( $WSO_ra->get_text() eq "succ", );

my $WSO_rb = find_reln($SWorkspace::elements[1], $SWorkspace::elements[2]);
$WSO_rb->insert();
my $WSO_rc = find_reln($SWorkspace::elements[3], $SWorkspace::elements[4]);
$WSO_rc->insert();
my $WSO_rd = find_reln($SWorkspace::elements[5], $SWorkspace::elements[6]);
$WSO_rd->insert();

ok( $WSO_rd->get_text()eq "same", );

ok( are_relns_compatible($WSO_ra, $WSO_rc), );
ok( not(are_relns_compatible($WSO_ra, $WSO_rd)), );


my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);

ok( exists $SWorkspace::groups{$WSO_ga}, );
ok( not($WSO_ga->get_underlying_reln()), );

$WSO_ga->set_underlying_reln($WSO_ra);
isa_ok( $WSO_ga->get_underlying_reln(), "SRuleApp" );

## applying relations
my $WSO_o1 = apply_reln($WSO_ra, $SWorkspace::elements[2]);
ok( UNIVERSAL::isa($WSO_o1, "SElement") , );
ok( $WSO_o1->get_mag()==4, );


## check_at_location
ok( SWorkspace->check_at_location({ start => 0,
                                    direction => DIR::RIGHT(),
                                    what => SObject->create(1),
                                }), );
ok( SWorkspace->check_at_location({ start => 0,
                                    direction => DIR::RIGHT(),
                                    what => SObject->create(1,2,3,6,7,9,9),
                                }), );

ok( not(SWorkspace->check_at_location({ start => 0,
                                    direction => DIR::RIGHT(),
                                    what => SObject->create(1,2,3,6,7,9,8),
                                })), );

ok( SWorkspace->check_at_location({ start => 0,
                                    direction => DIR::LEFT(),
                                    what => SObject->create(1),
                                }), );

ok( SWorkspace->check_at_location({ start => 3,
                                    direction => DIR::LEFT(),
                                    what => SObject->create(6),
                                }), );
## check
ok( SWorkspace->check_at_location({ start => 3,
                                    direction => DIR::LEFT(),
                                    what => SObject->create(2,3,6),
                                }), );


my $WSO_e2 = $SWorkspace::elements[2];
my $WSO_e2a = plonk_into_place(2, DIR::RIGHT(), SElement->create(3,0));
ok( $WSO_e2 eq $WSO_e2a );
ok( $WSO_e2 eq $SWorkspace::elements[2], );

dies_ok { plonk_into_place(2, DIR::RIGHT(), SElement->create(4,0))};


## extendibility
my $WSO_gb = SAnchored->create($SWorkspace::elements[1], $SWorkspace::elements[2], );
SWorkspace->add_group($WSO_gb);
 
ok( $WSO_gb->get_right_extendibility() == EXTENDIBILE::NO(), );
$WSO_gb->set_underlying_reln($WSO_rb);
ok( $WSO_gb->get_right_extendibility() == EXTENDIBILE::PERHAPS(), );
$WSO_gb->set_right_extendibility(EXTENDIBILE::NO());
ok( $WSO_gb->get_right_extendibility() == EXTENDIBILE::NO(), );

### More plonk_into_place stuff
SUtil::clear_all();
SWorkspace->init({seq => [qw( 1 1 1 7 8 9 1 1 7 8 9)]});
$WSO_o1 = $S::ASCENDING->build({ start => 7, end => 9});

my $plonked = plonk_into_place( 3, DIR::RIGHT(), $WSO_o1 );
isa_ok( $plonked, "SAnchored");
$plonked->structure_ok([7,8,9]);
ok( $SWorkspace::elements[3]->get_relation($SWorkspace::elements[4]), );

SWorkspace->remove_gp($plonked);
my $WSO_o2 = $S::DESCENDING->build({ start => 9, end => 7});
$WSO_o2->set_direction(DIR::LEFT());

my $plonked2 = plonk_into_place( 10, DIR::LEFT(), $WSO_o2 );
isa_ok( $plonked2, "SAnchored");
$plonked2->structure_ok([9,8,7]);

ok( $plonked eq plonk_into_place(5, DIR::LEFT(), $WSO_o1), );
ok( $plonked2 eq plonk_into_place(8, DIR::RIGHT(), $WSO_o2), );

SUtil::clear_all();
SWorkspace->init({seq => [qw( 7 1 1 2 2 3 3 7)]});

my $WSO_o3 = SObject->create([1, 1], [2,2], [3,3]);
for (@$WSO_o3) { $_->set_direction(DIR::RIGHT()) }
$WSO_o3->set_direction(DIR::RIGHT());

$plonked = plonk_into_place(1, DIR::RIGHT(), $WSO_o3);
isa_ok( $plonked, "SAnchored");
$plonked->structure_ok([[1,1], [2,2], [3,3]]);

ok( $plonked eq plonk_into_place(6, DIR::LEFT(), $WSO_o3), );

use strict;
use blib;
use Test::Seqsee;
plan tests => 10; 

use Seqsee;
INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

SWorkspace->init({seq => [qw( 1 1 1 2 2 2 3 3 3 3)]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();

my $WSO_rb = find_reln($SWorkspace::elements[1], $SWorkspace::elements[2]);
$WSO_rb->insert();
 
my $cl =new SCodelet("FindIfRelatedRelns", 100, { a => $WSO_ra, b => $WSO_rb});
my $tht = throws_thought_ok( $cl, "AreTheseGroupable");

my $WSO_rc = find_reln($SWorkspace::elements[3], $SWorkspace::elements[4]);
$WSO_rc->insert();
my $WSO_rd = find_reln($SWorkspace::elements[5], $SWorkspace::elements[4]);
$WSO_rd->insert();

$cl =new SCodelet("FindIfRelatedRelns", 100, { a => $WSO_rc, b => $WSO_rd});
$tht = throws_thought_ok( $cl, "ShouldIFlip");
 
$cl =new SCodelet("FindIfRelatedRelns", 100, { a => $WSO_ra, b => $WSO_rc});
$tht = throws_no_thought_ok($cl);

$cl =new SCodelet("FindIfRelatedRelns", 100, { a => $WSO_rb, b => $WSO_rc});
$tht = throws_no_thought_ok($cl);

my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], $SWorkspace::elements[2], );
SWorkspace->add_group($WSO_ga);
ok( $WSO_ga->describe_as($S::SAMENESS), );

my $WSO_gb = SAnchored->create($SWorkspace::elements[3], $SWorkspace::elements[4], $SWorkspace::elements[5], );
SWorkspace->add_group($WSO_gb);
ok( $WSO_gb->describe_as($S::SAMENESS), );

my $WSO_gc = SAnchored->create($SWorkspace::elements[6], $SWorkspace::elements[7], $SWorkspace::elements[8], );
SWorkspace->add_group($WSO_gc);
ok( $WSO_gc->describe_as($S::SAMENESS), );

my $WSO_Ra = find_reln($WSO_ga, $WSO_gb);
$WSO_Ra->insert();

my $WSO_Rb = find_reln($WSO_gb, $WSO_gc);
$WSO_Rb->insert();
 
$cl =new SCodelet("FindIfRelatedRelns", 100, { a => $WSO_Ra, b => $WSO_Rb});
$tht = throws_thought_ok( $cl, "AreTheseGroupable");

SUtil::clear_all();

SWorkspace->init({seq => [qw( 1 1 2 3 4 1 2 2 3 4 1 2 3 3 4)]});

my $gp_A = SWorkspace->rapid_create_gp([$S::ASCENDING],
                                       [['metonym', $S::SAMENESS, "each"],
                                        $SWorkspace::elements[0], 
                                        $SWorkspace::elements[1]
                                            ],
                                       $SWorkspace::elements[2], 
                                       $SWorkspace::elements[3], 
                                       $SWorkspace::elements[4]
                                           );
isa_ok( $gp_A, 'SAnchored');
$gp_A->structure_ok([[1,1],2,3,4]);
my $gp_B = SWorkspace->rapid_create_gp([$S::ASCENDING],
                                       
                                       $SWorkspace::elements[5], 
                                       [['metonym', $S::SAMENESS, "each"],
                                        $SWorkspace::elements[6], 
                                        $SWorkspace::elements[7]
                                            ],
                                       $SWorkspace::elements[8], 
                                       $SWorkspace::elements[9]
                                           );

my $gp_C = SWorkspace->rapid_create_gp([$S::ASCENDING],
                                       
                                       $SWorkspace::elements[10],
                                       $SWorkspace::elements[11],  
                                       [['metonym', $S::SAMENESS, "each"],
                                        $SWorkspace::elements[12], 
                                        $SWorkspace::elements[13]
                                            ],
                                       $SWorkspace::elements[14], 
                                           );

  

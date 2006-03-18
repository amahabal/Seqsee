use strict;
use blib;
use Test::Seqsee;
plan tests => 8; 
use Smart::Comments;
use Seqsee;
Seqsee->initialize_codefamilies;
Seqsee->initialize_thoughttypes;

use Class::Multimethods;
multimethod 'find_reln';

SWorkspace->init({seq => [qw( 1 1 2 3 )]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();
my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);

$WSO_ga->describe_as($S::SAMENESS);
$WSO_ga->annotate_with_metonym($S::SAMENESS, 'each');

my $WSO_gb = SAnchored->create($WSO_ga, $SWorkspace::elements[2], $SWorkspace::elements[3], );
SWorkspace->add_group($WSO_gb);
 

my $cl1;
$cl1 = new SCodelet('SetLiteralCat', 100, { object => $WSO_ga });
throws_no_thought_ok( $cl1 );
my $literal_11 = $S::LITERAL->build( { structure => [1,1] });
$WSO_ga->is_of_category_ok($literal_11);

my $cl2;
$cl2 = new SCodelet('SetLiteralCat', 100, { object => $WSO_gb });
throws_no_thought_ok( $cl2 );

my $literal_1123 = $S::LITERAL->build( { structure => [[1,1],2,3]});
## $literal_1123, ident $literal_1123
$WSO_gb->is_of_category_ok($literal_1123);

$WSO_ga->set_metonym_activeness(1);
throws_no_thought_ok($cl1);
throws_no_thought_ok($cl2);

my $literal_1 = $S::LITERAL->build( { structure => [1] });
## ident $literal_1
my $literal_123 = $S::LITERAL->build( { structure => [1,2,3] });
$WSO_ga->is_of_category_ok($literal_1);
$WSO_gb->is_of_category_ok($literal_123);

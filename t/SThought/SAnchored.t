use strict;
use blib;
use Test::Seqsee;
plan tests => 2; 

use Smart::Comments;
use Seqsee;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

Test::Stochastic::setup( times => 5);

SWorkspace->init({seq => [qw( 1 1 2 2 3 3)]});

my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);
$WSO_ga->describe_as( $S::SAMENESS);

my $tht = SThought->create( $WSO_ga );
my $lit_11 = $S::LITERAL->build({ structure => [1, 1]});
my $lit_1 = $S::LITERAL->build({ structure => 1});

fringe_contains( $tht, always => [ $lit_11, $S::SAMENESS ]);

$WSO_ga->annotate_with_metonym( $S::SAMENESS, "each");


$WSO_ga->set_metonym_activeness(1);
fringe_contains( $tht, always => [ $lit_1 ]);

 

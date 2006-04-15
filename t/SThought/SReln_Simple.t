use strict;
use blib;
use Test::Seqsee;
plan tests => 3; 

use Smart::Comments;
use Seqsee;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

Test::Stochastic::setup( times => 5);

SWorkspace->init({seq => [qw( 1 1 2 3 4)]});

my $WSO_ra = find_reln($SWorkspace::elements[2], $SWorkspace::elements[3]);
$WSO_ra->insert();
my $WSO_rb = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_rb->insert();
 
 
my $tht = SThought->create( $WSO_ra );
my $tht2 = SThought->create( $WSO_rb );
isa_ok( $tht, 'SThought::SReln_Simple');

fringe_contains( $tht,
                 always => [ $SWorkspace::elements[2], $SWorkspace::elements[3]]
                     );

action_contains( $tht2,
                 sometimes => [qw{SThought::AreTheseGroupable}],
                     );

use strict;
use blib;
use Test::Seqsee;
plan tests => 10; 

use Smart::Comments;
use Seqsee;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

Test::Stochastic::setup( times => 5);


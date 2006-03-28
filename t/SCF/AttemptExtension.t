use strict;
use blib;
use Test::Seqsee;
plan tests => 10; 

use Smart::Comments;
use Seqsee;
Seqsee->initialize_codefamilies;
Seqsee->initialize_thoughttypes;

use Class::Multimethods;
multimethod 'find_reln';

SWorkspace->init({seq => [qw( 1 1 2 3 )]});

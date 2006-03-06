use strict;
use blib;
use Test::Seqsee;
plan tests => 3; 

use Seqsee;
Seqsee->initialize_codefamilies;
Seqsee->initialize_thoughttypes;

SWorkspace->init({seq => [qw( 1 1 2 2)]});
my $cl = new SCodelet("FindIfRelated", 100, { a => $SWorkspace::elements[0],
                                              b => $SWorkspace::elements[1]
                                          });
my $tht = throws_thought_ok($cl, "SReln_Simple");

my $reln = $SWorkspace::elements[0]->get_relation($SWorkspace::elements[1]);
ok( $reln, );
ok( $SWorkspace::relations{$reln}, );


use strict;
use blib;
use Test::Seqsee;
plan tests => 7; 

use Smart::Comments;
use Seqsee;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

Test::Stochastic::setup( times => 5);

SWorkspace->init({seq => [qw( 1 1 2 3 4)]});

my $tht = SThought->create( $SWorkspace::elements[0] );
isa_ok( $tht, 'SThought::SElement');

my $lit_0 = $S::LITERAL->build({structure => 0});
my $lit_1 = $S::LITERAL->build({structure => 1});
my $lit_2 = $S::LITERAL->build({structure => 2});


fringe_contains( $tht, always => [ $lit_1, 'absolute_position_0' ]);
extended_fringe_contains( $tht, 
                          always => [ $lit_0, 
                                      $lit_2, 
                                      'absolute_position_1',
                                          ]);

my $tht2 = SThought->create( $SWorkspace::elements[0] );
my $tht3 = SThought->create( $SWorkspace::elements[1] );
ok( $tht eq $tht2, );
ok( $tht ne $tht3, );

my $arbit_cat = SCat::OfObj->new({builder => sub {},
                                  name => "arbit",
                                      });
fringe_contains( $tht, never => [ $arbit_cat ]);
$SWorkspace::elements[0]->add_category( $arbit_cat, 
                                        SBindings->new({bindings => {},
                                                       raw_slippages => {},
                                                       object => $SWorkspace::elements[0]
                                                         }  ));
fringe_contains( $tht, always  => [ $arbit_cat ]);

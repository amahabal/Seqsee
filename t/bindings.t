use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 10; }

use SBindings;
use SBindings::Blemish;
use SBuiltObj;

CONSTRUCT:{
  my $bb = new SBindings::Blemish;
  isa_ok $bb, "SBindings::Blemish";

  $bb->set_where(2);
  $bb->set_starred(4);
  $bb->set_real("4");

  ok(1, "Alright, the methods seem to exist.");

  $bb = new SBindings::Blemish( { where   => 2,
				  starred => 4,
				  real    => SBuiltObj->new_deep(4, 4),
				}
			      );
  $bb->where_ok(2);
  $bb->starred_ok(4);
  $bb->real_ok([4, 4]);
}

CONSTRUCT: {
  my $bindings = new SBindings();
  isa_ok $bindings, "SBindings";
  
  $bindings->set_values_of({ what => "foo" });
  $bindings->add_blemish
    (
     SBindings::Blemish->new({ where => 3, starred => 2, 
			       real  => SBuiltObj->new_deep(7, 7),
			     }));
  $bindings->add_blemish
    (
     SBindings::Blemish->new({ where => 4, starred => 2, 
			       real  => SBuiltObj->new_deep(8, 8),
			     }));
  $bindings->where_ok([3, 4]);
  $bindings->starred_ok([2, 2]);
  $bindings->real_ok([[7,7], [8,8]]);
  $bindings->value_ok(what => "foo");
}

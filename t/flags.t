use Test::More tests => 7;
use blib;
use strict;

BEGIN { use_ok("SFlags"); }

isa_ok($Dflag::is,     "Dflag");
isa_ok($Dflag::has,    "Dflag");
isa_ok($Bflag::both,   "Bflag");
isa_ok($Bflag::change, "Bflag");

cmp_ok($Dflag::is->{arity},  'eq', 0);
cmp_ok($Dflag::has->{arity}, 'eq', 1);

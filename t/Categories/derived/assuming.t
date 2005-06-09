use blib;
use Test::Seqsee;
BEGIN { plan tests => 9; }

use SCat::ascending;
use SBindings;

my $cat = $SCat::ascending::ascending;

my $cat2 = $cat->derive_assuming(start => 1);
dies_ok  { $ret = $cat2->build() }         "Needs the missing arguments";
lives_ok { $ret = $cat2->build(end => 4) } "all arguments present";

isa_ok($ret, "SBuiltObj", "Built object is a SBuiltObj");
cmp_deeply([$ret->flatten], [1,2,3,4], "derived built the right object");

$bindings = $cat2->is_instance($ret);
isa_ok($bindings, "SBindings");
is($bindings->{end}, 4);

$bindings = $cat2->is_instance(1, 2, 3, 4, 5, 6);
is($bindings->{start}, 1);
is($bindings->{end}, 6);

$bindings = $cat2->is_instance(3, 4, 5);
undef_ok($bindings);


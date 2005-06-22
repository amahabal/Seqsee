use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 14; }

use SCat::ascending;
use SBindings;
use SBuiltObj;
use SInt;

my $cat = $SCat::ascending::ascending;

my $cat2 = $cat->derive_assuming(start => 1);
my $ret;
dies_ok  { $ret = $cat2->build() }         "Needs the missing arguments";
lives_ok { $ret = $cat2->build(end => 4) } "all arguments present";

isa_ok($ret, "SBuiltObj", "Built object is a SBuiltObj");
$ret->structure_ok([1, 2, 3, 4],  "derived built the right object");

my $bindings;
$bindings = $cat2->is_instance($ret);
isa_ok($bindings, "SBindings");
is($bindings->{end}, 4);

$bindings = $cat2->is_instance(SBuiltObj->new(1, 2, 3, 4, 5, 6));
is($bindings->{start}, 1);
is($bindings->{end}, 6);

$bindings = $cat2->is_instance(SBuiltObj->new(3, 4, 5));
undef_ok($bindings);

{
	my $blemished_obj2 = SBuiltObj->new(
				3, 
				$SBlemish::double::double
				   ->blemish(SInt->new(4)),
				5, 6, 7);


	my $bindings = $cat2->is_instance($blemished_obj2);
	undef_ok $bindings;
	#diag $bindings->{start};
}


#diag "cat  instancer is: $cat->{instancer}";
#diag "cat2 instancer is: $cat2->{instancer}";

{
	use SBlemish::double;
	my $blemished_obj = SBuiltObj->new(
				1, 
				$SBlemish::double::double
				   ->blemish(SInt->new(2)),
				3, 4, 5);
	$blemished_obj->structure_ok([1, [2, 2], 3, 4, 5]);

	my $bindings = $cat->is_instance($blemished_obj);
	is($bindings->{start}, 1);
	is($bindings->{end}, 5);
}

#diag "cat  instancer is: $cat->{instancer}";
#diag "cat2 instancer is: $cat2->{instancer}";


{
	my $blemished_obj2 = SBuiltObj->new(
				3, 
				$SBlemish::double::double
				   ->blemish(SBuiltObj->new(4)),
				5, 6, 7);


	my $bindings = $cat2->is_instance($blemished_obj2);
	undef_ok $bindings;
	#diag $bindings->{start};
}


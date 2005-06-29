use blib;
use Test::Seqsee;
BEGIN { plan tests => 9; }

use SBuiltObj;
use SCat;
use SBlemish;
use SBlemish::double;
use SCat::mountain;
use SPos;

# use Smart::Comments;

my $double = $SBlemish::double::double;
my $mtn    = $SCat::mountain::mountain;
my $pos2   = SPos->new(2);

my $bo = $mtn->build( { foot => 2, peak => 5 } );
my $bo_bl = $bo->apply_blemish_at( $double, $pos2 );

$bo_bl->structure_ok( [ 2, [ 3, 3 ], 4, 5, 4, 3, 2 ] );

my $item2 = $bo_bl->items()->[1];
instance_of_cat_ok $item2, $double;

my $bindings = $item2->get_cat_bindings($double);
### $bindings
isa_ok $bindings, "HASH";
isa_ok $bindings->{what}, "SInt";

cmp_deeply [ sort $mtn->get_att()->members ], [qw{foot peak}];

is $mtn->guess_attribute( $bo_bl, "foot" ), 2;
is $mtn->guess_attribute( $bo_bl, "peak" ), 5;

$bindings = $mtn->is_instance($bo_bl);
is $bindings->{value}{foot}, 2;
is $bindings->{value}{peak}, 5;

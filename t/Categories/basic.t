use blib;
use Test::Seqsee;
BEGIN { plan tests => 11; }

use SBuiltObj;

use_ok("SCat");

my $cat = new SCat({attributes => [qw/start end/],
		    empty_ok   => 1,
		    guesser_pos_of => { start => 0, end => -1}
		   });
isa_ok( $cat, "SCat" );
$cat->set_builder(
  sub {
    my ( $self, $args_ref ) = @_;
    die "need start" unless $args_ref->{start};
    die "need end"   unless $args_ref->{end};
    my $ret = new SBuiltObj;
    $ret->set_items( [ $args_ref->{start} .. $args_ref->{end} ] );
    $ret;
  }
);

$cat->compose;
my $ret;

dies_ok  { $cat->build() } "Needs the arguments";
dies_ok  { $cat->build( { start => 1 } ) } "Needs the arguments";
lives_ok { $ret = $cat->build( { start => 1, end => 3 } ) }
  "Needs the arguments";

isa_ok( $ret, "SBuiltObj", "Built object is a SBuiltObj" );
$ret->structure_ok( [ 1, 2, 3 ], "built the right object" );

my $bindings = $cat->is_instance($ret);
$bindings->value_ok(end => 3);

$bindings = $cat->is_instance( SBuiltObj->new( { items => [ 3, 4, 5, 6 ] } ) );
$bindings->value_ok(start => 3);
$bindings->value_ok(end => 6);

$bindings = $cat->is_instance( SBuiltObj->new( { items => [ 3, 6, 7 ] } ) );
undef_ok($bindings);


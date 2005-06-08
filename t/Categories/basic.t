use blib;
use Test::Seqsee;
BEGIN { plan tests=> 21; }

use SBuiltObj;
use SBindings;

use_ok("SCat");

my $cat = new SCat;
isa_ok($cat, "SCat");
$cat->add_attributes(qw/start end/);
$cat->{builder} = sub {
  my ($self, %args) = @_;
  die "need start" unless $args{start};
  die "need end"   unless $args{end};
  my $ret = new SBuiltObj;
  $ret->set_items($args{start} .. $args{end});
  $ret;
};
$cat->{instancer} = sub {
  my ($self, $builtobj) = @_;
  my @items =  @{$builtobj->items};
  my $len = scalar(@items);
  for my $i (0 .. $len - 2) {
    return undef unless $items[$i+1] == $items[$i] + 1;
  }
  return SBindings->new(start => $items[0],
			end => $items[-1]
		       );
};

my $ret;

dies_ok  {        $cat->build() } "Needs the arguments";
dies_ok  {        $cat->build(start => 1) } "Needs the arguments";
lives_ok { $ret = $cat->build(start => 1, end => 3) } "Needs the arguments";

isa_ok($ret, "SBuiltObj", "Built object is a SBuiltObj");
cmp_deeply($ret->items, [1,2,3], "built the right object");

my $bindings = $cat->is_instance($ret);
isa_ok($bindings, "SBindings");
is($bindings->{end}, 3, "Bindings correct when obj is SObj");

$bindings = $cat->is_instance(3, 4, 5, 6);
is($bindings->{start}, 3, "Bindings correct for 3 4 5 6");
is($bindings->{end}, 6, "Bindings correct for 3 4 5 6");

$bindings = $cat->is_instance(3, 6, 7);
undef_ok($bindings);

my $cat2 = $cat->subcat_assuming(start => 1);
dies_ok  { $ret = $cat2->build() }         "Needs the missing arguments";
lives_ok { $ret = $cat2->build(end => 4) } "all arguments present";

isa_ok($ret, "SBuiltObj", "Built object is a SBuiltObj");
cmp_deeply($ret->items, [1,2,3,4], "derived built the right object");

$bindings = $cat2->is_instance($ret);
isa_ok($bindings, "SBindings");
is($bindings->{end}, 4);

$bindings = $cat2->is_instance(1, 2, 3, 4, 5, 6);
is($bindings->{start}, 1);
is($bindings->{end}, 6);

$bindings = $cat2->is_instance(3, 4, 5);
undef_ok($bindings);


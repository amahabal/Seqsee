use blib;
use Test::Seqsee;

BEGIN { plan tests => 5; }

use SBuiltObj;
use SBindings;
use SCat;

use SBlemish;
use SUtil;

my $bl = new SBlemish;
isa_ok($bl, "SBlemish");

$bl->{blemisher} = sub {
  my ($self, $builtobj, %args) = @_;
  my $new_obj = new SBuiltObj;
  $new_obj->set_items( @{ $builtobj->items }, @{ $builtobj->items } );
  $new_obj;
};

$bl->{unblemisher} = sub {
  my ($self, $builtobj) = @_;
  my @items = @{$builtobj->items};
  my $len = scalar(@items);
  return undef unless $len % 2 == 0;
  my $half = $len / 2;
  for my $i (0 .. $half - 1) {
    return undef unless equal_when_flattened($items[$i], $items[$i + $half]);
  }
  my $new_obj = new SBuiltObj;
  $new_obj->set_items(@items[0 .. $half - 1]);
  $new_obj;
};

my $obj = SBuiltObj->new()->set_items(1, 2, 1, 2);
my $more_blemished = $bl->blemish($obj);
my $unblemished    = $bl->unblemish($obj);


isa_ok($more_blemished, "SBuiltObj");
isa_ok($unblemished, "SBuiltObj");
cmp_deeply([$more_blemished->flatten], [qw{1 2 1 2 1 2 1 2}]);
cmp_deeply([$unblemished->flatten], [1, 2]);


#XXX there should also be some test to check that the two new objects are marked for their origins.

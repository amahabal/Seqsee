use blib;
use Test::Seqsee;
BEGIN { plan tests => 3; }

use SBuiltObj;
use SPos;
use SBlemish;

my $bl = new SBlemish;

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


SECOND: {
  my $pos = new SPos 2;
  
  my $obj = new SBuiltObj(4, 5, 6, 7);
  
  $obj2 = $obj->apply_blemish_at($bl, $pos);
  cmp_deeply([$obj2->flatten], [4, 5, 5, 6, 7]);
  
  cmp_ok($obj, 'ne', $obj2);
}

LAST_BUT_ONE: {
  my $pos = new SPos -2;  
  my $obj = new SBuiltObj(4, 5, 6, 7);
  $obj2 = $obj->apply_blemish_at($bl, $pos);
  cmp_deeply([$obj2->flatten], [4, 5, 6, 6, 7]);
}

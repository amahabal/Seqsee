package SCat::mountain;
use SCat;

our $mountain = new SCat;
my $cat = $mountain;

$cat->add_attributes(qw/foot peak/);
$cat->{builder} = sub{
  my ($self, %args) = @_;
  die "need start" unless $args{foot};
  die "need end"   unless $args{peak};
  my $ret = new SBuiltObj;
  $ret->set_items($args{foot} .. $args{peak}, 
		  reverse($args{foot} .. $args{peak} - 1));
  $ret->add_cat($cat, %args);
  $ret;
};

$cat->{instancer} = sub {
  my ($self, $builtobj) = @_;
  my @items = @{$builtobj->items};
  return new SBindings() unless @items;
  my $len = scalar(@items);
  return undef if $len % 2 == 0;
  my $mid = $items[ ($len - 1) / 2 ];
  my $obj = $cat->build(foot => $items[0],
			peak => $mid
		       );
  my $builtitems = $obj->items;
  for my $i (0 .. $len - 1) {
    return undef unless $builtitems->[$i] == $items[$i];
  }
  my $bindings = new SBindings(foot => $items[0], peak => $mid);
  $bindings;
};

$cat->{position_finder}{peak} = 
  sub {
    my $bo = shift;
    my $items = $bo->items;
    my $count = scalar(@$items);
    my $ret = ($count - 1) / 2;
    return [ $ret ];
  };

1;

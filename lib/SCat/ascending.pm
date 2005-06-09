package SCat::ascending;
use SCat;

our $ascending = new SCat;
my $cat = $ascending;

$cat->add_attributes(qw/start end/);
$cat->{builder} = sub {
  my ($self, %args) = @_;
  die "need start" unless $args{start};
  die "need end"   unless $args{end};
  my $ret = new SBuiltObj;
  $ret->set_items($args{start} .. $args{end});
  $ret->add_cat($cat, %args);
  $ret;
};

$cat->{instancer} = sub{
  my ($self, $builtobj) = @_;
  my @items =  @{$builtobj->items};
  my $len = scalar(@items);
  return SBindings->new() unless @items;
  for my $i (0 .. $len - 2) {
    return undef unless $items[$i+1]->{'m'} == $items[$i]->{'m'} + 1;
  }
  return SBindings->new(start => $items[0]->{'m'},
			end => $items[-1]->{'m'}
		       );
};

1;

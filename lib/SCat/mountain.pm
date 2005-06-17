package SCat::mountain;
use SCat;

our $mountain = new SCat;
my $cat = $mountain;

$cat->add_attributes(qw/foot peak/);
$cat->{builder} = sub{
  my ($self, %args) = @_;
  die "need foot" unless $args{foot};
  die "need peak" unless $args{peak};
  my $ret = new SBuiltObj;
  $ret->set_items($args{foot} .. $args{peak}, 
		  reverse($args{foot} .. $args{peak} - 1));
  $ret->add_cat($cat, %args);
  $ret;
};


$cat->{position_finder}{peak} = 
  sub {
    my $bo = shift;
    my $items = $bo->items;
    my $count = scalar(@$items);
    my $ret = ($count - 1) / 2;
    return [ $ret ];
  };

$cat->{guesser_pos} = { foot => 0 };
$cat->{empty_ok} = 1;
$cat->compose();


1;

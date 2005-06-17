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

$cat->{empty_ok} = 1;

$cat->{position_finder}{peak} = 
  sub {
    my $bo = shift;
    my $items = $bo->items;
    my $count = scalar(@$items);
    my $ret = ($count - 1) / 2;
    return [ $ret ];
  };

$cat->{guesser}{foot} =
  sub {
    my ($self, $object) = @_;
    my ($subobj) = $object->find_at_position(SPos->new(1));
    my @int_vals = $subobj->as_int();
    if (@int_vals == 1) { return $int_vals[0]; }
    return undef;
  };

$cat->{guesser}{peak} =
  sub {
    my ($self, $object) = @_;
    my $items = $object->items;
    my $itemcnt = scalar @$items;
    return undef if $itemcnt % 2 == 0;
    my ($subobj) = $items->[($itemcnt-1)/2];
    my @int_vals = $subobj->as_int();
    if (@int_vals == 1) { return $int_vals[0]; }
    return undef;
  };

$cat->generate_instancer;


1;

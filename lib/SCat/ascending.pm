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
  $ret->set_items([$args{start} .. $args{end}]);
  $ret->add_cat($cat, \%args);
  $ret;
};

$cat->{guesser_pos} = { start => 0, end => -1 };
$cat->{empty_ok} = 1;
$cat->compose();

1;

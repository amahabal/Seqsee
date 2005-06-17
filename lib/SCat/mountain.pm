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

$cat->{instancer} = sub {
  my ($self, $builtobj) = @_;
  return SBindings->new() if $builtobj->is_empty;
  my $foot_guess = $self->guess_attribute($builtobj, "foot");
  my $peak_guess = $self->guess_attribute($builtobj, "peak");
  return undef unless (defined($foot_guess) and defined($peak_guess));
  my $guess_built = $self->build( foot => $foot_guess,
				  peak => $peak_guess);
  my $bindings = $builtobj->structure_blearily_ok($guess_built);
  if ($bindings) {
	$bindings->{foot} = $foot_guess;
	$bindings->{peak} = $peak_guess;
  }

  return $bindings;
};

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

1;

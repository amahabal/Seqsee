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

$cat->{instancer_} = sub{
  my ($self, $builtobj) = @_;
  return SBindings->new() if $builtobj->is_empty;
  my $start_guess = $self->guess_attribute($builtobj, "start");
  my $end_guess = $self->guess_attribute($builtobj, "end");
  return undef unless (defined($start_guess) and defined($end_guess));
  my $guess_built = $self->build( start => $start_guess,
                                  end   => $end_guess);
  my $bindings = $builtobj->structure_blearily_ok($guess_built);
  if ($bindings) {
        $bindings->{start} = $start_guess;
        $bindings->{end}   = $end_guess;
  }
  
  return $bindings;
};

$cat->{guesser}{start} = sub {
  my ($self, $bo) = @_;
  my $obj = $bo->items()->[0];
  my @int_vals = $obj->as_int();
  if (@int_vals == 1) { return $int_vals[0]; }
  return undef;
};

$cat->{guesser}{end} = sub {
  my ($self, $bo) = @_;
  my $obj = $bo->items()->[-1];
  my @int_vals = $obj->as_int();
  if (@int_vals == 1) { return $int_vals[0]; }
  return undef;
};

$cat->{empty_ok} = 1;
$cat->generate_instancer;

1;

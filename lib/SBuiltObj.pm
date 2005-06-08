package SBuiltObj;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  my @items = map { ref($_) ? $_->clone : $_ } @_;
  $self->set_items(@items);
  $self->{cats} = {};
  $self;
}

sub set_items{
  my $self = shift;
  $self->{items} = [@_];
  $self;
}

sub items{
  shift->{items};
}

sub add_cat{
  my $self = shift;
  my $cat  = shift;
  unless (UNIVERSAL::isa($cat, "SCat")) {
    die "The argument to add_cat must be a category";
  }
  my %bindings = @_;
  foreach (keys %bindings) {
    die "Category $cat does not take the attribute $_" unless
      $cat->has_attribute($_);
  }
  $SCat::Str2Cat{$cat} = $cat;
  $self->{cats}{$cat} = \%bindings;
  $self;
}

sub get_cat_bindings{
  my ($self, $cat) = @_;
  return undef unless exists $self->{cats}{$cat};
  $self->{cats}{$cat};
}

sub get_cats{
  my $self = shift;
  map { $SCat::Str2Cat{$_} } keys %{$self->{cats}};
}

sub flatten{
  my $self = shift;
  return map { ref $_ ? $_->flatten() : $_ } @{$self->{items}};
}

sub find_at_position{
  my ($self, $position) = @_;
  my $range = $self->range_given_position($position);
  return $self->subobj_given_range($range);
}

sub range_given_position{
  my ($self, $position) = @_;
  return $position->{rangesub}->($self);
}

sub subobj_given_range{
  my ($self, $range) = @_;
  my @ret;
  my $items = $self->items;
  for (@$range) {
    my $what = $items->[$_];
    return undef if not defined $what;
    push @ret, $what;
  }
  if (scalar(@ret) == 1) {
    return $ret[0] if ref $ret[0];
    return SBuiltObj->new($ret[0]);
  }
  return SBuiltObj->new(@ret);
}

sub get_position_finder{ #XXX should really deal with the category of the built object, and I have not dealt with that yet....
  my ($self, $str) = @_;
  my $sub = $self->{position_finder}{$str};
  die "Could not find any way for finding the position '$str' for $self" unless $sub;
  return $sub;
}

sub splice{
  my $self = shift;
  my $from = shift;
  my $len = shift;
  my $items = $self->{items};
  splice(@$items, $from, $len, @_);
  $self;
}

sub apply_blemish_at{
  my ($self, $blemish, $position) = @_;
  $self = $self->clone;
  my $range = $self->range_given_position($position);
  die "position $position undefined for $self" unless $range;
  # XXX should check that range is contiguous....
  my $subobj = $self->subobj_given_range($range);
  my $blemished = $blemish->blemish($subobj);
  my $range_start = $range->[0];
  my $range_length = scalar(@$range);
  $self->splice($range_start, $range_length, $blemished);
  $self;
}

sub clone{
  my $self = shift;
  my $new_obj = new SBuiltObj;
  my $items = $new_obj->{items};
  foreach (@{$self->{items}}) {
    push (@$items, ref($_) ? $_->clone() : $_ ); 
  }
  while (my($k, $v) = each %{$self->{cats}}) {
    $new_obj->{cats}{$k} = $v; #XXX should I clone this???
  }
  $new_obj;
}


1;

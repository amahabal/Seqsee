package SBuiltObj;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  my @items = map { ref($_) ? $_->clone : $_ } @_;
  $self->set_items(@items);
  $self->{cats} = {};
  $self;
}

sub new_deep{
  my $package = shift;
  my $self = bless {}, $package;
  my @items = map { 
    if (ref $_) {
      if (ref($_) eq 'ARRAY') {
	$package->new_deep(@$_);
      } else {
	$_->clone;
      }
    } else {
      $_
    }
  } @_;
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

sub subobj_given_range{ # Name should be changed!
  my ($self, $range) = @_;
  my @ret;
  my $items = $self->items;
  for (@$range) {
    my $what = $items->[$_];
    die "out of range" if not defined $what;
    push @ret, $what;
  }
  @ret;
}

sub get_position_finder{ #XXX should really deal with the category of the built object, and I have not dealt with that yet....
  my ($self, $str) = @_;
  my @cats = $self->get_cats();
  my @cats_with_position = grep { $_->has_named_position($str) } @cats;
  die "Could not find any way for finding the position '$str' for $self" unless @cats_with_position;
  # XXX what if multiple categories have a position of this name??
  return $cats_with_position[0]->{position_finder}{$str};
}

sub splice{
  my $self = shift;
  my $from = shift;
  my $len = shift;
  my $items = $self->{items};
  splice(@$items, $from, $len, @_);
  $self;
}

sub apply_blemish_at{ # Assumption: position returns a single item
  my ($self, $blemish, $position) = @_;
  $self = $self->clone;
  my $range = $self->range_given_position($position);
  die "position $position undefined for $self" unless $range;
  # XXX should check that range is contiguous....
  my @subobjs = $self->subobj_given_range($range);
  if (@subobjs >= 2) {
    die "applying blemished over a range longer than 1 not yet implemented";
  }
  my $blemished = $blemish->blemish($subobjs[0]);
  #$blemished->show();
  my $range_start = $range->[0];
  my $range_length = scalar(@$range);
  $self->splice($range_start, $range_length, $blemished);
  #$self->show;
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

sub show{
  my $self = shift;
  print "Showing the structure of $self:\n";
  print "\nItems:\n";
  foreach (@{$self->items}) {
    print "\t$_\n";
    if (ref $_) {
      $_->show_shallow(2);
    }
  }
}

sub show_shallow{
  my ($self, $depth) = @_;
  foreach (@{$self->items}) {
    print "\t" x $depth;
    print "$_\n";
    if (ref $_) {
      $_->show_shallow($depth + 1);
    }
  }
}

sub compare_deep{ #XXX need tests for this...
  my ($self, $other) = @_;
  return undef unless ref($other);
  my $self_items = $self->items;
  my $other_items = $other->items;
  return undef unless scalar(@$self_items) == scalar(@$other_items);
  my $count = scalar(@$self_items);
  for my $i (0 .. $count - 1) {
    if (ref $self_items->[$i]) {
      return undef unless $self_items->[$i]->compare_deep($other_items->[$i]);
    } elsif (ref $other_items->[$i]) {
      return undef;
    } else {
      return undef unless $self_items->[$i] eq $other_items->[$i];
    }
  }
  return 1;
}

1;

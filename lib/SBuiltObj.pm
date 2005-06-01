package SBuiltObj;

sub new{
  my $package = shift;
  bless {}, $package;
}

sub set_items{
  my $self = shift;
  $self->{items} = [@_];
  $self;
}

sub items{
  shift->{items};
}

sub flatten{
  my $self = shift;
  return map { ref $_ ? $_->flatten() : $_ } @{$self->{items}};
}

sub find_at_position{
  my ($self, $position) = @_;
  return $position->{sub}->($self);
}

sub get_position_finder{ #XXX should really deal with the category of the built object, and I have not dealt with that yet....
  my ($self, $str) = @_;
  my $sub = $self->{position_finder}{$str};
  die "Could not find any way for finding the position '$str' for $self" unless $sub;
  return $sub;
}

1;

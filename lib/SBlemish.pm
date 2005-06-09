package SBlemish;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  $self;
}

sub blemish{
  my $self = shift;
  return $self->{blemisher}->($self, @_);
}

sub unblemish{
  my $self = shift;
  return $self->{unblemisher}->($self, @_);
}

sub is_blemished{
  my $self = shift;
  my $obj  = shift;
  $self->{instancer}->($self, $obj);
}

1;

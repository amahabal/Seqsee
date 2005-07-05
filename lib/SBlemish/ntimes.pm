package SBlemish::ntimes;

my $builder = sub {
  my ( $self, $args ) = @_;
  my $object = $args->{what};
  my $n      = $args->{n};
  my @arr = map { $object } (1 .. $n);
  return SBuiltObj->new_deep( @arr );
};

my $guesser = {
  what => sub {
    my ( $self, $bo ) = @_;
    #print "In what guesser\n";
    $bo->items()->[0];
  },
  n => sub {
    my ( $self, $bo ) = @_;
    #print "In n guesser\n";
    return scalar( @{ $bo->items() });
  },
};

my $guesser_flat = {
  what => sub { return;},
  n => sub { return; },
};

our $ntimes = new SBlemish(
  {
   builder => $builder,
   empty_ok => 0,
   guesser_of => $guesser,
   guesser_flat_of => $guesser_flat,
   attributes => [qw{n}],
  }
);

1;

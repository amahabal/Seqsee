package SUtility;

sub toss($) {
  ( rand() <= shift ) ? 1 : 0;
}

sub pprint{
  my($what) = shift;
  if ($what =~ /HASH/) {
    if (exists $what->{str}) {
      return $what->{str};
    } else {
      return $what;
    }
  }
  if ($what =~ /ARRAY/) {
    return join("", "[", join(", ", map { pprint($_) } @$what ), "]");
  }
  return $what;
}

sub min{
  my $min = 1000000;
  for (@_) {
    $min = $_ if $_ < $min;
  }
  $min;
}

sub max{
  my $max = -1000000;
  for (@_) {
    $max = $_ if $_ > $max;
  }
  $max;
}

1;

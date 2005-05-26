package SUtil;
our @EXPORT = qw{uniq equal_when_flattened};
our @ISA = qw{Exporter};

sub uniq{
  my %hash;
  for (@_) {
    $hash{$_} = $_;
  }
  values %hash;
}

sub equal_when_flattened{
  my ($obj1, $obj2) = @_;
  unless (ref $obj1) {
    if (ref $obj2) {
      return undef;
    } else {
      return $obj1 == $obj2;
    }
  }
  return undef unless ref $obj2;
  my @flattened1 = $obj1->flatten;
  my @flattened2 = $obj2->flatten;
  return undef unless scalar(@flattened1) == scalar(@flattened2);
  for my $i (0 .. scalar(@flattened1) - 1) {
    return undef unless $flattened1[$i] == $flattened2[$i];
  }
  return 1;
}

1;

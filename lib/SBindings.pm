package SBindings;
sub new{
  my $package = shift;
  bless { @_ }, $package;
}

1;

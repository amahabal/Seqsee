package SNode;
use strict;

sub new{
  my $package = shift;
  my $name    = shift;
  bless { name => $name }, $package;
}

1;

package SBindings;
use strict;

sub new {
  my $package = shift;
  bless {@_}, $package;
}

1;

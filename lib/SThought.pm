package SThought;
use strict;

sub contemplate{
  my $thought = shift;
  $thought->contemplate_add_descriptors();
  $thought->spread_activation_from_components();
  $thought->contemplate_add_descriptors();
}

sub spread_activation_from_components{
  die "This Should Never Have Been Called. Not Implemented Yet";
}

sub contemplate_add_descriptors{
  die "This default implementation of contemplate_add_descriptors() just dies: Override this.";
}

1;

package SCodelet;
use strict;

sub new{
  my ($package, $family, $urgency, %args) = @_;
  bless [$family, $urgency, $::CurrentEpoch, \%args], $package;
}

sub run{
  my $self = shift;
  $::CurrentCodelet = $self;
  $::CurrentCodeletFamily = $self->[0];
  #XXX Probably need checking for freshness of this codelet
  no strict;
  &{"SCF::$self->[0]::run"}($self->[3]);
}

1;

package SElement;
use strict;

use SObject;
our @ISA = qw{SObject};

sub new{
  my $package     = shift;
  my $magnitude   = shift;
  my $self = bless { mag => $magnitude }, $package;
  $self->init;
}

1;

package SNode;
use strict;
use SDescs;

our @ISA = qw{SDescs};

sub new{
  my $package = shift;
  my $name    = shift;
  bless { name  => $name, 
	  str   => "{$name}",
	  descs => [],
	}, $package;
}

sub halo{
  my $self = shift;
  # XXX Currently I can just pretend to use all the links...
  #     But that'll change, as I understand what is needed better
  return $self->descriptors;
}


1;

package SElement;
use strict;

use SObject;
use SFlags;
our @ISA = qw{SObject};

sub new{
  my $package     = shift;
  my $magnitude   = shift;
  my $self = bless { mag => $magnitude }, $package;
  my $concept = SNet->fetch($magnitude, create => 1);
  $self->init;
  $self->add_desc( new SDesc($concept, $Dflag::is) );
  $self;
}

sub contemplate_add_descriptors{
  # XXX
}

sub spread_activation_from_components{
  # XXX
}

sub components{
  my $self = shift;
  return $self->descriptors();
}

1;

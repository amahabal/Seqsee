package SElement;
use strict;

use SObject;
use SFlags;
our @ISA = qw{SObject};

sub new{
  my $package     = shift;
  my $magnitude   = shift;
  my $self = bless { mag => $magnitude }, $package;
  $self->set_str;
  my $concept = SNet->fetch($magnitude, create => 1);
  $self->init;
  $self->add_desc( new SDesc($concept, $Dflag::is) );
  $self;
}

sub set_str{
  my $self = shift;
  $self->{str} = "<$self->{mag}>";
}

sub contemplate_add_descriptors{
  # XXX
}

1;

package SElement;
use strict;

use SObject;
use SFlags;
our @ISA = qw{SObject SFascination};

sub new{
  my $package     = shift;
  my $magnitude   = shift;
  my $self = bless { mag => $magnitude }, $package;
  $self->set_str;
  my $concept = SNet::fetch("Number::".$magnitude, 
			    create => 1, 
			    magnitude => $magnitude);
  $self->init;
  $self->add_desc( new SDesc($concept, $Dflag::is) );
  $self;
}

sub set_str{
  my $self = shift;
  $self->{str} = "<$self->{mag}>";
}

sub contemplate_add_descriptors{
  my $self = shift;
  if ($self->{mag} > 10 or $self->{mag} < 0) {
    $self->add_desc( new SDesc($SNet::node_surprising, $Dflag::is) );
  }
}

1;

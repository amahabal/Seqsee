package SGroup;
use strict;

use SObject;
use SFlags;
our @ISA = qw{SObject};

sub new{
  my $package = shift;
  my $self    = bless { elements => [@_] }, $package;
  $self->init;
  $self->set_str;
  $self->set_extent; 
  $self;
}

sub set_str{
  my $self = shift;
  $self->{str} = "( ".join(", ", map { $_->{str} } @{$self->{elements}})." )";
}

sub set_extent{
  my $self = shift;
  $self->{left_edge} = SUtility::min(map { $_->{left_edge} } @{$self->{elements}});
  $self->{right_edge} = SUtility::max(map { $_->{right_edge} } @{$self->{elements}});
}

1;

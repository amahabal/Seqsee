package SObject;
use strict;

use Sconsts;
use SDescs;
use SDesc;
use SHistory;
use SThought;
use SNet;
our @ISA = qw{SDescs SHistory SThought};

sub init{
  my $self = shift;
  $self->{descs}   = [];
  $self->{bonds}   = {};
  $self->{bonds_p} = {};
  $self->{groups}  = {};
  $self->{groups_p}= {};
  $self->{history} = [];
  $self->history_add("Created");
  $self;
}

sub bond_insert{
  my ($self, $bond) = @_;
  my $type = ($bond->{build_level} == Built::Fully) ? "bonds" : "bonds_p";
  $self->{$type}{$bond} = $bond;
  $self->history_add("Bond $bond added");
}

sub bond_promote{
  my ($self, $bond) = @_;
  delete $self->{bonds_p}{$bond};
  $self->{bonds}{$bond} = $bond;
  $self->history_add("Bond $bond promoted");
}

sub bond_remove{
  my ($self, $bond) = @_;
  # faster to just delete from both without checking which
  delete $self->{bonds_p}{$bond};
  delete $self->{bonds}{$bond};
  $self->history_add("Bond $bond removed");
}

sub group_insert{
  my ($self, $group) = @_;
  my $type = ($group->{build_level} == Built::Fully) ? "groups" : "groups_p";
  $self->{$type}{$group} = $group;
}

sub group_promote{
  my ($self, $group) = @_;
  delete $self->{groups_p}{$group};
  $self->{groups}{$group} = $group;
}

sub group_remove{
  my ($self, $group) = @_;
  # faster to just delete from both without checking which
  delete $self->{groups_p}{$group};
  delete $self->{groups}{$group};
}

sub halo{
  my $self = shift;
  return $self->descriptors();
}

1;

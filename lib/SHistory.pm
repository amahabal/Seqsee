package SHistory;
use strict;

sub history_add{
  my $self = shift;
  my $msg = shift;
  my $critical = shift;
  my $date   = $::CurrentEpoch;
  my $family = $::CurrentCodelet->[0];
  unshift @{$self->{history}}, [$date, $msg, $critical, $family];
}

sub last_critical_change_time{
  my $self = shift;
  foreach (@{$self->{history}}) {
    return $_->[0] if $_->[2];
  }
  return 0;
}

sub is_outdated{ # Can only be called within a codelet body
  my $self = shift;
  $self->last_critical_change_time > $::CurrentCodelet->[2];
}

sub spill_history{
  my $self = shift;
  my $string;
  my $critical;
  foreach (@{$self->{history}}) {
    $critical = $_->[2] ? "*" : " ";
    $string .= "$critical   $_->[0]\t$_->[3]\t$_->[1]\n";
  }
  $string;
}

1;

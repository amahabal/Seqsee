package SWorkspace;
use strict;

our ($elements_count, $bonds_count,   $bonds_p_count);
our ($groups_count,   $groups_p_count);
our @elements = ();
our $bonds    = {};
our $bonds_p  = {};
our $groups   = {};
our $groups_p = {};

sub setup{
  my $package = shift;
  $bonds    = {};
  $bonds_p  = {};
  $groups   = {};
  $groups_p = {};
  $bonds_count   = 0;
  $bonds_p_count = 0;
  $groups_count  = 0;
  $groups_p_count= 0;
  @elements = ();
  $elements_count = 0;
  SWorkspace->insert(@_);
}

sub insert{
  my $package = shift;
  for (@_) {
    push(@elements, (ref($_) and $_->isa("SElement"))? $_ : SElement->new($_));
    $elements[-1]->{left_edge} = $elements[-1]->{right_edge} = $elements_count;
    $elements_count++;
  }
}

1;

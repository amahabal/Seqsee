package SWorkspace;
use strict;

our $elements_count;
our @elements  = ();

sub setup{
  my ( $package, @rest ) = @_;
  @elements = ();
  $elements_count = 0;
  SWorkspace->insert_elements(@rest);
}

sub insert_elements{
  my ( $package, @rest ) = @_;
  for (@rest) {
    push @elements, (ref($_) and $_->isa("SElement")) ? $_ : SElement->new({mag => $_});
    $elements[-1]->set_left_edge($elements_count);
    $elements[-1]->set_right_edge($elements_count);
    $elements_count++;
  }
}

1;

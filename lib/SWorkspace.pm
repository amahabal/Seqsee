package SWorkspace;
use strict;
use Perl6::Subs;

our $elements_count;
our @elements  = ();

method setup($package: *@rest){
  @elements = ();
  $elements_count = 0;
  SWorkspace->insert_elements(@rest);
}

method insert_elements($package: *@rest){
  for (@rest) {
    push @elements, (ref($_) and $_->isa("SElement")) ? $_ : SElement->new({mag => $_});
    $elements[-1]->set_left_edge($elements_count);
    $elements[-1]->set_right_edge($elements_count);
    $elements_count++;
  }
}

1;

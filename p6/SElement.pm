class SElement is SObject;
# XXX Just trying out how the thing will look in P6.
# Maybe I should design the program in P6 first...

has Int $.magnitude;

method create(Int $magnitude){
  my $el = new SElement(magnitude => $magnitude);
  $el.add_attribute('magnitude', XXX);
  $el.add_attribute('object_type', XXX);
  $el.update_strength;
  $el;
}

class SElement is SObject;

has Int $.magnitude;

method create(Int $magnitude){
  my $el = new SElement(magnitude => $magnitude);
  $el.add_attribute('magnitude', XXX);
  $el.add_attribute('object_type', XXX);
  $el.update_strength;
  $el;
}

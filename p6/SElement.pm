class SElement is SObject;

has Int $.magnitude;

method create(Int $magnitude){
  my $el = new SElement(magnitude => $magnitude);
  
  $el.update_strength;
  $el;
}

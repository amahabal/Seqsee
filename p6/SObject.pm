class SObject;

does SHistory;
is   SThought;

has Num %.attributes is shape(Attribute);

method add_attribute(Attribute $attr){
  $_.add_history("Attribute '$attr' added");
  %.attributes{$attr} = 1;
}

method clear_attributes(){
  %.Attributes = ();
}

method get_attribute_keys(){
  return {.key}>> %.attributes;
}

method get_common_attributes(SEntity $other){
  
}

class SCodelet;


has String $.family;
has Num    $.urgency;
has Int    $.eob       = { $*CurrentEpoch };     #Epoch of Birth
has        %.options;

# I want to check that family is supplied.
method new(class $c: +$family, +$urgency, *%options){
  $family err die "family missing in Codelet.new";
  $c.bless :family{$family} :urgency{$urgency} <== %options;
}
# submethod BUILD(){}

method run(){
  $*CurrentCodelet = $_;
  for %.options.values {
    next unless $_.can("is_outdated");
    return 0 if $_.is_outdated;
  }
  SCF::($.family).run(%.options);
}

1;

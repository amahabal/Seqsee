class SCodelet;


has String $.family;
has Num    $.urgency;
has Int    $.eob       = { $*CurrentEpoch };     #Epoch of Birth
has        %.options;

# I want to check that family is supplied.
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

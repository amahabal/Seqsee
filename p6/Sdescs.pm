role Sdescs{

  has @.desc = ();  # Holds the descriptions

  method add_desc($desc)   {...}
  method remove_desc($desc){...}

}

class SDesc does Sdescs{
  has SNode $.descriptor;
  has Dflag $.flag;
  has       $.label;
}

class SBond is SDesc{
  has Bflag $.bflag;
}

class Schange{
  has $.oldv;
  has $.newv;
  has $.reln;
}

1;

role SDescs{

  has @.descs = ();  # Holds the descriptions

  method add_desc($desc)   {...}
  method remove_desc($desc){...}

}

role SBDescs does SDescs{
}

class SDesc does SDescs{
  has SNode $.descriptor;
  has Dflag $.flag;
  has       @.labels;
}

class SBDesc does SBDescs does SFascination{
  has SNode $.descriptor;
  has Dflag $.flag;
  has Bflag $.bflag;
  has       @.label;
  has       $.str;
  sub new(){...} #XXX How do I add the constraint here?
}

class SBond does SBDescs does SFascination{
  has $.from;
  has $.to;
  method new(){...} # Again, how do I write the constraints?
}

class Schange{
  has $.oldv;
  has $.newv;
  has $.reln;
}

1;

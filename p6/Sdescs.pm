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

class SBDesc does SBDescs{
  has SNode $.descriptor;
  has Dflag $.flag;
  has Bflag $.bflag;
  has       @.labels;
}

class SBond does SBDescs{
  has $.from;
  has $.to;
}

class Schange{
  has $.oldv;
  has $.newv;
  has $.reln;
}

1;

package Dflag;

sub new { 
  my $package = shift;
  my $arity   = shift;
  my $str     = shift;
  my $pl_str  = shift;
  $pl_str ||= $str;
  bless {arity => $arity, str => $str, pl_str => $pl_str }, $package; 
}

our $is  = new Dflag(0, "is", "are");
our $has = new Dflag(1, "has", "have");


package Bflag;

sub new { 
  my $pack = shift;
  my $str  = shift;
  bless { str => $str }, $pack;
}
 
our $both   = new Bflag("both");
our $change = new Bflag("change");

1;

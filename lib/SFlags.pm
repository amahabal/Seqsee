package Dflag;

sub new { 
  my $package = shift;
  my $arity   = shift;
  my $str     = shift;
  bless {arity => $arity, str => $str }, $package; 
}

our $is  = new Dflag(0, "is");
our $has = new Dflag(1, "has");


package Bflag;

sub new { 
  my $pack = shift;
  my $str  = shift;
  bless { str => $str }, $pack;
}
 
our $both   = new Bflag("both");
our $change = new Bflag("change");

1;

package Dflag;

sub new { 
  my $package = shift;
  my $arity   = shift;
  bless {arity => $arity }, $package; 
}

our $is  = new Dflag(0);
our $has = new Dflag(1);


package Bflag;

sub new { bless {}, shift; }
 
our $both   = new Bflag;
our $change = new Bflag;

1;

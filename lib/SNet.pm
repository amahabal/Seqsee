package SNet;
use strict;

use SNode;
use SFlags;

our %Nodes;

foreach (
	 qw{ 1 2 3 4 5 6 7 8 9 10
	     succ pred
	  }
	) {
  $Nodes{$_} = new SNode($_);
}

for (1..9) {
  $Nodes{$_}->add_desc( SDesc->new($Nodes{$_ + 1},
				   $Dflag::has,
				   "successor",)
		      );
}

for (2..10) {
  $Nodes{$_}->add_desc( SDesc->new($Nodes{$_ - 1},
				   $Dflag::has,
				   "predecessor")
		      );
}

sub fetch{
  my $package = shift;
  my $what    = shift;
  my %args    = @_;
  return $Nodes{$what} if exists $Nodes{$what};
  return undef unless $args{create};
  $Nodes{$what} = new SNode($what);
}

1;

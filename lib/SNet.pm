package SNet;
use strict;

use SNode;

no strict 'refs';
foreach (
	 qw{ 1 2 3 4 5 6 7 8 9 10
	     succ pred
	  }
	) {
  ${"node_$_"} = new SNode($_);
}

use strict 'refs';

1;

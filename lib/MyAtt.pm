package MyAtt;
use strict;
no warnings;

use Filter::Simple sub {
   s/([\$@%&])(\w*)\.(\w+)/
	$1 eq '$' ? ($2 ? ("\$$2"."->{'$3'}") : "\$self->{'$3'}") : 
		($2 ? "$1\{\$$2"."->{'$3'}}" : "$1\{\$self->{'$3'}}")/ge; 
   print;
   $_;
};

1;

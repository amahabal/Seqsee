use Test::More tests => 2;
use blib;

BEGIN {use_ok('SThought')};
can_ok('SThought', qw{ contemplate
		       contemplate_add_descriptors
		       spread_activation_from_components
		    });

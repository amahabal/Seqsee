use Test::More tests => 3;
use Test::Exception;

use strict;
use blib;


BEGIN{
  use_ok("SElement");
}

my $e1 = SElement->new(3);
isa_ok($e1, "SObject");
cmp_ok($e1->{mag}, '==', 3);

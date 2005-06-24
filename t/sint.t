use blib;
use Test::Seqsee;
BEGIN { plan tests => 2; }

use SInt;

my $si = new SInt({mag => 5});
isa_ok $si, "SInt";
is $si->get_mag(), 5;


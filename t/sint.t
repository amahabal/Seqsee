use blib;
use Test::Seqsee;
BEGIN { plan tests => 2; }

use SInt;

my $si = new SInt(5);
isa_ok $si, "SInt";
is $si->{'m'}, 5;


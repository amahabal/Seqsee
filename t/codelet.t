use Test::More tests => 9;
use Test::MockObject;
use blib;

use STestInit;

BEGIN {
  Test::MockObject->fake_module('SCF::family_foo');
}

BEGIN{
  $SCF::family_foo::logger = Log::Log4perl->get_logger('');
  $SCF::family_foo::logger;
  sub SCF::family_foo::run{
    my $args = shift;
    return (97 + $args->{a});
  }
}


BEGIN {use_ok("SCodelet")};

$::CurrentEpoch = 20;

my $cl = new SCodelet("family_foo", 10, a => 3, b => 5);

isa_ok($cl, "SCodelet");
cmp_ok($cl->[0], 'eq', "family_foo");
cmp_ok($cl->[1], 'eq', "10");
cmp_ok($cl->[2], 'eq', "20");
cmp_ok($cl->[3]{a}, 'eq', 3);
cmp_ok($cl->run(), 'eq', 100);

cmp_ok($::CurrentCodelet,       'eq', $cl);
cmp_ok($::CurrentCodeletFamily, 'eq', "family_foo");

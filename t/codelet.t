use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 10; }

# use MyFilter;
use Test::MockObject;
use SCodelet;

BEGIN {
  Test::MockObject->fake_module('SCF::family_foo');
  Test::MockObject->fake_module('SCF::family_malformed');
  sub SCF::family_foo::run {
    my $args = shift;
    97 + $args->{a};
  }
}

$::CurrentEpoch = 20;
my $cl = SCodelet->new("family_foo", 10, a => 3, b => 5);


isa_ok $cl,         "SCodelet";
is     $cl->[0],    "family_foo"; # family name
is     $cl->[1],    10;           # urgency
is     $cl->[2],    20;           # epoch of birth
is     $cl->[3]{a}, 3;            # other args

# Running, and its consequences
is     $cl->run(),  100;          # run
is     $::CurrentCodelet,        $cl;
is     $::CurrentCodeletFamily, "family_foo";

my $cl2 = SCodelet->new("family_nonexistant", 20);
throws_ok { $cl2->run() } "SErr::Code::UnknownFamily";

my $cl3 = SCodelet->new("family_malformed", 20);
throws_ok { $cl3->run() } "SErr::Code::MalFormed";


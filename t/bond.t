#XXX MUST CHANGE NOW THAT I HAVE CHANGED HOW DESCRIPTIONS WORK

use Test::More tests => 11;
use Test::MockObject;
use Test::Exception;
use blib;
use strict;

BEGIN{
  Test::MockObject->fake_module('SNode');
  Test::MockObject->fake_module('SLink');
}

BEGIN{
  use_ok("SDescs");
  use_ok("SDesc");
  use_ok("SBond");
};

can_ok("SBond", qw{new});

my ($bond);
my $node_1      = bless {}, "SNode";
my $node_2      = bless {}, "SNode";
my $node_3      = bless {}, "SNode";
my $node_succ   = bless {}, "SNode";

my $wso_11      = bless {}, "Swso";
my $wso_22      = bless {}, "Swso";


# The constructor only takes positional arguments, from and to.
dies_ok  { $bond = new SBond() };
lives_ok { $bond = new SBond($wso_11, $wso_22) };
isa_ok($bond, "SBDescs");
isa_ok($bond, "SFascination");

ok(defined($SBond::FascCallBacks));

# Initial state
cmp_ok($bond->{from},      "eq", $wso_11);
cmp_ok($bond->{to},        "eq", $wso_22);

#XXX Several things need to be added here; no bond descriptions here so far, but for that I need add_desc and remove_desc thought out...

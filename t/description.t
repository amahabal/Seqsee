use Test::More tests => 40;
use Test::MockObject;
use Test::Exception;
use blib;
use strict;

BEGIN{
  Test::MockObject->fake_module('SNode');
};

BEGIN{
  use_ok("SFlags");
  use_ok("SDesc");
  use_ok("SBDesc"); # Bond descriptions..
};


can_ok("SDesc", qw{new});
can_ok("SBDesc", qw{new});

############
############ DESCRIPTIONS

my ($desc, $desc2);
my $node_1      = bless {}, "SNode";
my $node_2      = bless {}, "SNode";
my $node_3      = bless {}, "SNode";
my $node_succ   = bless {}, "SNode";

# The constructor for SDesc needs both a descriptor and Dflag, and dies o/w
dies_ok  { $desc = new SDesc() };
dies_ok  { $desc = new SDesc($node_3) };
lives_ok { $desc = new SDesc($node_3, $Dflag::is) };

# Not only must both args be supplied but also extra args corresponding to the arity of the flag:

dies_ok  { $desc2 = new SDesc($node_3, $Dflag::has) };
dies_ok  { $desc2 = new SDesc($node_3, $Dflag::is,  "length") };
lives_ok { $desc2 = new SDesc($node_3, $Dflag::has, "length") };

isa_ok($desc2, "SDescs");
isa_ok($desc2, "SFascination");
ok(defined($SDesc::FascCallBacks));


cmp_ok($desc->{descriptor},  'eq', $node_3);
cmp_ok($desc->{flag},        'eq', $Dflag::is);
cmp_ok($desc2->{descriptor}, 'eq', $node_3);
cmp_ok($desc2->{flag},       'eq', $Dflag::has);
cmp_ok($desc2->{label}[0],   'eq', "length");

my $desc3 = new SDesc($node_3, $Dflag::has, "length");
my $desc4 = new SDesc($node_3, $Dflag::has, "breadth");

ok(    $desc2->similar($desc3));
ok(not $desc->similar($desc2));
ok(not $desc->similar($desc4));
ok(not $desc2->similar($desc4));

#############
############# BOND DESCRIPTORS

my($bdesc1, $bdesc2);

# The constructor for SBDesc needs a descriptor, a Dflag and a Bflag, and dies o/w
dies_ok  { $bdesc1 = new SBDesc() };
dies_ok  { $bdesc1 = new SBDesc($node_3) };
dies_ok  { $bdesc1 = new SBDesc($node_3, $Dflag::is) };
lives_ok { $bdesc1 = new SBDesc($node_3, $Dflag::is, $Bflag::both) };

# Not only must both args be supplied but also extra args corresponding to the arity of the flag:

dies_ok  { $bdesc2 = new SBDesc($node_3, $Dflag::has, $Bflag::both) };
dies_ok  { $bdesc2 = new SBDesc($node_3, $Dflag::is,  $Bflag::both, "length")};
lives_ok { $bdesc2 = new SBDesc($node_3, $Dflag::has, $Bflag::both, "length")};


isa_ok($bdesc2, "SBDescs");
isa_ok($bdesc2, "SFascination");
ok(defined($SBDesc::FascCallBacks));

cmp_ok($bdesc1->{descriptor},  'eq', $node_3);
cmp_ok($bdesc1->{flag},        'eq', $Dflag::is);
cmp_ok($bdesc1->{bflag},        'eq', $Bflag::both);
cmp_ok($bdesc2->{descriptor}, 'eq', $node_3);
cmp_ok($bdesc2->{flag},       'eq', $Dflag::has);
cmp_ok($bdesc2->{bflag},       'eq', $Bflag::both);
cmp_ok($bdesc2->{label}[0],   'eq', "length");


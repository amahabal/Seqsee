use Test::More tests => 19;
use Test::MockObject;
use Test::Exception;
use blib;
use strict;

BEGIN{
  use_ok("SFlags");
  use_ok("SDescs");
  use_ok("SDesc");
  use_ok("SBDescs");
  use_ok("SBDesc");
};

TODO: {
  local $TODO = "lots more work needed!";
  can_ok("SDescs", qw{remove_desc});
}

my $node_1      = bless {}, "SNode";
my $node_2      = bless {}, "SNode";
my $node_3      = bless {}, "SNode";
my $node_succ   = bless {}, "SNode";

my $x  = bless { descs => [] }, "SDescs";
my $d1 = new SDesc($node_1, $Dflag::is);
my $d2 = new SDesc($node_1, $Dflag::is);
my $d3 = new SDesc($node_1, $Dflag::has, "length");
my $d4 = new SDesc($node_1, $Dflag::has, "breadth");

can_ok("SDescs", "add_desc");

$d1->add_desc($d3);
$d2->add_desc($d4);

$x->add_desc($d1);
# Just a single description so far...
cmp_ok(scalar(@{ $x->{descs} }), '==', 1);
# But that description has a meta description...
cmp_ok(scalar(@{ $x->{descs}[0]{descs} }), '==', 1);
# Still only a single description...
$x->add_desc($d2);
# But that has two meta descriptions...
cmp_ok(scalar(@{ $x->{descs} }), '==', 1);
cmp_ok(scalar(@{ $x->{descs}[0]{descs} }), '==', 2);
$x->add_desc($d3);
$x->add_desc($d4);
cmp_ok(scalar(@{ $x->{descs} }), '==', 3);

TODO: {
  local $TODO = "lots more work needed!";
  can_ok("SBDescs", qw{remove_desc});
}

can_ok("SBDescs", "add_desc");

my $bx  = bless { descs => [] }, "SBDescs";
my $bd1 = new SBDesc($node_1, $Dflag::is,  $Bflag::both);
my $bd2 = new SBDesc($node_1, $Dflag::is,  $Bflag::both);
my $bd3 = new SBDesc($node_1, $Dflag::has, $Bflag::both, "length");
my $bd4 = new SBDesc($node_1, $Dflag::has, $Bflag::both, "breadth");


$bd1->add_desc($bd3);
$bd2->add_desc($bd4);

$bx->add_desc($bd1);
# Just a single description so far...
cmp_ok(scalar(@{ $bx->{descs} }), '==', 1);
# But that description has a meta description...
cmp_ok(scalar(@{ $bx->{descs}[0]{descs} }), '==', 1);
# Still only a single description...
$bx->add_desc($bd2);
# But that has two meta descriptions...
cmp_ok(scalar(@{ $bx->{descs} }), '==', 1);
cmp_ok(scalar(@{ $bx->{descs}[0]{descs} }), '==', 2);
$bx->add_desc($bd3);
$bx->add_desc($bd4);
cmp_ok(scalar(@{ $bx->{descs} }), '==', 3);


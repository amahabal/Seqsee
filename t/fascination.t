use Test::More tests => 8;
use Test::MockObject;
use Test::Exception;
use blib;
use strict;

BEGIN { use_ok("SFascination") };
can_ok("SFascination", "update_fascinations");

package foo;
use SFascination;
our @ISA = qw{SFascination};
our @FascOrder = qw{a b c};
our $x = 0;
our $FascCallBacks = {a => sub { ++$x; return $x  },
		      b => sub { ++$x; ++$x; return $x  },
		      c => sub { ++$x; return $x }
		     };

package main;

my $o1 = bless {}, "foo";
my $o2 = bless {}, "foo";

$o1->update_fascinations;
$o2->update_fascinations;

cmp_ok($o1->{f}{a},'eq', 1);
cmp_ok($o1->{f}{b},'eq', 3);
cmp_ok($o1->{f}{c},'eq', 4);

$o1->update_fascinations;
cmp_ok($o1->{f}{a},'eq', 9);
cmp_ok($o1->{f}{b},'eq', 11);
cmp_ok($o1->{f}{c},'eq', 12);

use blib;
use MyFilter;
use Test::Seqsee;
use SErr;

BEGIN { plan tests => 16; }

my $x = { a => 10, b => [5, 6] };
is $x.a, 10;
cmp_deeply $x.b, [5, 6];
is @x.b[1], 6;

for my $self ($x) {
  is $.a, 10;
  cmp_deeply $.b, [5, 6];
  is @.b[1], 6;
}

sub foo{
  ATT r t u;
  return (r => $r, t => $t, u => $u);
}

throws_ok { foo() } SErr::Att::Missing;
throws_ok { foo( r => 1, t => 2, u => 3, v => 4) } SErr::Att::Extra;
my %hash;
lives_ok  { %hash = foo( r => 1, t => 2, u => 3) };
is $hash{u}, 3;

sub bar{
  ATT r t u *;
  return (r => $r, t => $t, u => $u);
}

throws_ok { bar() } SErr::Att::Missing;
lives_ok { %hash = bar( r => 1, t => 2, u => 3, v => 4) };
is $hash{u}, 3;


package Foo;
sub new { bless {}, shift }
sub add7 { my $self = shift; return $.x + 7 }

package main;

my $y = new Foo;
$y.x = 5;
is &y.add7(), 12;

my $str = '&y' . '.add7';
eval $str;
ok $@;

for my $self ($y) {
  is &.add7(), 12;
}


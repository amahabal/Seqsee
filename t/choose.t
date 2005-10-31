use strict;
use blib;
use Test::Seqsee;
plan tests => 14; 

use SChoose;

my $chooser = SChoose->create(); # From numbers...

my @arr = (1,2,3,4);
my %Counter;
for (1..1000) {
    my $choice = $chooser->(\@arr);
    $Counter{$choice}++;
}

ok($Counter{2} >= 180 and $Counter{2} <= 220);
ok($Counter{4} >= 360 and $Counter{4} <= 440);


$chooser = SChoose->create({ grep => sub {
                                 return ($_[0] % 2) == 0 
                             },
                         }); # from even 

@arr = (1,2,3,4);
%Counter = ();
for (1..1000) {
    my $choice = $chooser->(\@arr);
    $Counter{$choice}++;
}
ok($Counter{2} >= 300 and $Counter{2} <= 360);
ok($Counter{4} >= 600 and $Counter{2} <= 720);


$chooser = SChoose->create({ map => sub {
                                 return $_[0]->[0];
                             },
                         }); # From numbers...

@arr = ([1], [2], [3], [4]);
%Counter = ();
for (1..1000) {
    my $choice = $chooser->(\@arr);
    $Counter{$choice}++;
}

ok($Counter{$arr[1]} >= 180 and $Counter{$arr[1]} <= 220);
ok($Counter{$arr[3]} >= 360 and $Counter{$arr[3]} <= 440);

$chooser = SChoose->create({ map => sub {
                                 return $_[0]->[0];
                             },
                             grep => sub {
                                 return $_[0]->[0] % 2 == 0;
                             },
                         }); # From numbers...

@arr = ([1], [2], [3], [4]);
%Counter = ();
for (1..1000) {
    my $choice = $chooser->(\@arr);
    $Counter{$choice}++;
}

ok($Counter{$arr[1]} >= 300 and $Counter{$arr[1]} <= 360);
ok($Counter{$arr[3]} >= 600 and $Counter{$arr[3]} <= 720);


$chooser = SChoose->create({map => sub {
                                return 0;
                            },
                        });

@arr = (1,2,3,4);
%Counter = ();
for (1..1000) {
    my $choice = $chooser->(\@arr);
    $Counter{$choice}++;
}
ok($Counter{2} >= 210 and $Counter{2} <= 290);
ok($Counter{4} >= 210 and $Counter{2} <= 290);


@arr = (1,2,3,4);
%Counter = ();
for (1..1000) {
    my $choice = SChoose->choose(\@arr);
    $Counter{$choice}++;
}

#diag $Counter{2};
#diag $Counter{4};
ok($Counter{2} >= 170 and $Counter{2} <= 230);
ok($Counter{4} >= 360 and $Counter{2} <= 440);

@arr = (1,2,3,4);
my @names = qw(one two three four);
%Counter = ();
for (1..1000) {
    my $choice = SChoose->choose(\@arr, \@names);
    $Counter{$choice}++;
}
#diag $Counter{two};
#diag $Counter{four};

ok($Counter{two} >= 180 and $Counter{two} <= 220);
ok($Counter{four} >= 360 and $Counter{four} <= 440);

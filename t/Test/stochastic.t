use strict;
use blib;
use Test::Seqsee;
plan tests => 11; 

my $sub1 = sub {
    if (SUtil::toss(0.5)) {
        return;
    }
    SErr::NeedMoreData->throw(payload => bless({}, 'SCF::Foo'));
};

my $sub2 = sub {
    SErr::NeedMoreData->throw(payload => bless({}, 'SCF::Foo'));
};

my $sub3 = sub {
    if (SUtil::toss(0.5)) {
        return;
    }
    SErr::NeedMoreData->throw(payload => bless({}, 'SThought::Bar'));
};

code_throws_stochastic_ok($sub1, ['', 'Foo']);
code_throws_stochastic_ok $sub2, ['Foo'];
code_throws_stochastic_ok $sub3, ['', 'Bar'];

code_throws_stochastic_nok $sub2, ['', 'Foo'];
code_throws_stochastic_nok $sub3, ['Foo', 'Bar'];

code_throws_stochastic_all_and_only_ok($sub1, ['', 'Foo']);
code_throws_stochastic_all_and_only_ok $sub2, ['Foo'];
code_throws_stochastic_all_and_only_ok $sub3, ['', 'Bar'];

code_throws_stochastic_all_and_only_nok($sub1, ['']);
code_throws_stochastic_all_and_only_nok $sub2, ['Foo', ''];
code_throws_stochastic_all_and_only_nok $sub3, ['Bar'];

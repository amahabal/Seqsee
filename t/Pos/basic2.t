use lib 'genlib';
use strict;
use Test::Seqsee;
plan tests => 19;

#use MyFilter;

my $mtn = $S::MOUNTAIN;
my $bo = $mtn->build( { foot => 3, peak => 5 } );

ok UNIVERSAL::isa( "SPos::Forward",  "SPos" );
ok UNIVERSAL::isa( "SPos::Backward", "SPos" );
Absolute: {
    my @objs;

    my $pos_1 = new SPos(1);
    isa_ok $pos_1, "SPos::Forward";

    # isa_ok $pos_1->{finder}, "SPosFinder";
    @objs = $bo->get_at_position($pos_1);
    ok( @objs == 1 );
    cmp_ok $objs[0]->get_structure, 'eq', 3;

    my $pos_1_copy = new SPos(1);
    is $pos_1, $pos_1_copy;

    my $pos_m2 = new SPos(-2);
    isa_ok $pos_m2, "SPos::Backward";

    #isa_ok $pos_m2->{finder}, "SPosFinder";
    @objs = $bo->get_at_position($pos_m2);
    ok( @objs == 1 );
    cmp_ok $objs[0]->get_structure, 'eq', 4;

    my $pos_m6 = new SPos(-6);
    isa_ok $pos_m6, "SPos::Backward";

    #isa_ok $pos_m6->{finder}, "SPosFinder";
    throws_ok { @objs = $bo->get_at_position($pos_m6) } "SErr::Pos::OutOfRange";
}

is(SPos->new(3), SPos->new(3, 'Forward'), 'Forward not needed for +ve index');
is(SPos->new(-3), SPos->new(-3, 'Backward'));
isnt(SPos->new(3), SPos->new(3, 'Backward'));
isnt(SPos->new(-3), SPos->new(-3, 'Forward'));
lives_ok { my $x = SPos->new(0, 'Forward') };
lives_ok { my $x = SPos->new(0, 'Backward') };
dies_ok { my $x = SPos->new(0) };

use Class::Multimethods;
multimethod 'find_reln';
multimethod 'apply_reln';
my $rel = find_reln(SPos->new(2), SPos->new(1));
my $p = apply_reln($rel, apply_reln($rel, SPos->new(1)));
is $p, SPos->new(-1, 'Forward');


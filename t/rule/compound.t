use strict;
use lib 'genlib';
use Test::Seqsee;
plan tests => 33;

use Class::Multimethods;
use SRule;
use SRuleApp;
use Smart::Comments;
multimethod q{find_reln};
multimethod q{apply_reln};
multimethod q{createRule};
multimethod q{plonk_into_place};

SWorkspace->init( { seq => [qw( 1 1 2 3 1 2 2 3 4 1 2 3 3 4 5 1 2 3 4 4 5 6)] } );

my $WSO_ga
    = plonk_into_place( 0, $DIR::RIGHT, SObject->QuickCreate( [ [ 1, 1 ], 2, 3 ], $S::ASCENDING ) );
my $WSO_gb = plonk_into_place( 4, $DIR::RIGHT,
    SObject->QuickCreate( [ 1, [ 2, 2 ], 3, 4 ], $S::ASCENDING ) );
my $WSO_gc = plonk_into_place( 9, $DIR::RIGHT,
    SObject->QuickCreate( [ 1, 2, [ 3, 3 ], 4, 5 ], $S::ASCENDING ) );
my $WSO_gd = plonk_into_place( 15, $DIR::RIGHT,
    SObject->QuickCreate( [ 1, 2, 3, [ 4, 4 ], 5, 6 ], $S::ASCENDING ) );

my $WSO_ra = find_reln( $WSO_ga, $WSO_gb );
$WSO_ra->insert();

my $WSO_rb = find_reln( $WSO_gb, $WSO_gc );
$WSO_rb->insert();

is_deeply(
    apply_reln( $WSO_ra, $WSO_gb )->get_structure(),
    [ 1, 2, [ 3, 3 ], 4, 5 ],
    "basic sanity"
);
is_deeply(
    apply_reln( $WSO_ra->get_type(), $WSO_gb )->get_structure(),
    [ 1, 2, [ 3, 3 ], 4, 5 ],
    "basic sanity"
);

my $rule1 = createRule($WSO_ra);
my $rule2 = createRule($WSO_rb);

isa_ok $rule1, "SRule";
is $rule1, $rule2, "Memoized!";

my $ruleapp1 = $rule1->CreateApplication(
    {   start => $WSO_gb,
        state => 0,
        direction => $DIR::RIGHT,
    }
);

is_deeply( $ruleapp1->GetItems(), [$WSO_gb], q{Items, ruleapp1} );
is_deeply( $ruleapp1->GetStates(), [0] );
lives_ok { $ruleapp1->ExtendRight() } "Extending ruleapp right";
is_deeply( $ruleapp1->GetItems(), [ $WSO_gb, $WSO_gc ], q{Items, ruleapp1} );
is_deeply( $ruleapp1->GetStates(), [ 0, 0 ] );

lives_ok { $ruleapp1->ExtendLeft() } "Extending ruleapp left";
is_deeply( $ruleapp1->GetItems(), [ $WSO_ga, $WSO_gb, $WSO_gc ], q{Items, ruleapp1} );
is_deeply( $ruleapp1->GetStates(), [ 0, 0, 0 ] );

my $ruleapp2 = $rule1->AttemptApplication(
    {   start => $WSO_ga,
        terms => 4,
        direction => $DIR::RIGHT,
    }
);
ok( $ruleapp2, );

is_deeply( $ruleapp2->GetItems(), [ $WSO_ga, $WSO_gb, $WSO_gc, $WSO_gd ], q{Items, ruleapp2} );
is_deeply( $ruleapp2->GetStates(), [ 0, 0, 0, 0 ] );
ok( not( $ruleapp2->ExtendLeft() ), );
is_deeply( $ruleapp2->GetItems(), [ $WSO_ga, $WSO_gb, $WSO_gc, $WSO_gd ], q{Items, ruleapp2} );
is_deeply( $ruleapp2->GetStates(), [ 0, 0, 0, 0 ] );

my $ruleapp3 = $rule1->AttemptApplication(
    {   start => $WSO_ga,
        terms => 1,
        direction  => $DIR::RIGHT
    }
);
## Items: $ruleapp3->GetItems()
ok( $ruleapp3->ExtendRight(2), "Extending multiple steps");
## Items: $ruleapp3->GetItems()
is_deeply( $ruleapp3->GetItems(), [ $WSO_ga, $WSO_gb, $WSO_gc ], q{Items, ruleapp3} );
ok( not ($ruleapp3->ExtendLeft(2)), );
is_deeply( $ruleapp3->GetItems(), [ $WSO_ga, $WSO_gb, $WSO_gc ], q{Items, ruleapp3} );

SWorkspace->init( { seq => [qw( 1 1 2 2 3 3 3 4 4 4 5 5 5 5 6 6 6 6)] } );
my @groups = (
    plonk_into_place( 0, $DIR::RIGHT, SObject->QuickCreate( [ 1, 1 ], $S::SAMENESS ) ),
    plonk_into_place( 2, $DIR::RIGHT, SObject->QuickCreate( [ 2, 2 ], $S::SAMENESS ) ),
    plonk_into_place( 4, $DIR::RIGHT, SObject->QuickCreate( [ 3, 3, 3 ], $S::SAMENESS ) ),
    plonk_into_place( 7, $DIR::RIGHT, SObject->QuickCreate( [ 4, 4, 4 ], $S::SAMENESS ) ),
    plonk_into_place( 10, $DIR::RIGHT, SObject->QuickCreate( [ 5, 5, 5, 5 ], $S::SAMENESS ) ),
    plonk_into_place( 14, $DIR::RIGHT, SObject->QuickCreate( [ 6, 6, 6, 6 ], $S::SAMENESS ) ),
);

ok( $groups[2], "groups defined");
ok( not ($groups[2]->get_metonym_activeness()), 'metonyms not active');
$groups[2]->is_of_category_ok($S::SAMENESS);

my $WSO_rc = find_reln( $groups[0], $groups[1] );
$WSO_rc->insert();

my $WSO_rd = find_reln( $groups[1], $groups[2] );
$WSO_rd->insert();

my $rule3 = createRule($WSO_rd);
my $rule4 = createRule( $WSO_rc, $WSO_rd );

my $ruleapp4 = $rule3->AttemptApplication( { start => $groups[1], terms => 3, direction => $DIR::RIGHT } );
ok( not($ruleapp4), );

$ruleapp4 = $rule3->AttemptApplication( { start => $groups[1], terms => 2, direction => $DIR::RIGHT } );
is_deeply( $ruleapp4->GetItems(), [ @groups[ 1, 2 ] ], q{Items, ruleapp4} );
is_deeply( $ruleapp4->GetStates(), [ 0, 0 ] );

my $ruleapp5 = $rule4->AttemptApplication(
    {   start      => $groups[0],
        terms      => 5,
        from_state => 1,
        direction  => $DIR::RIGHT
    }
);
ok( not($ruleapp5), );
$ruleapp5 = $rule4->AttemptApplication(
    {   start      => $groups[0],
        terms      => 5,
        from_state => 0,
        direction  => $DIR::RIGHT
    }
);
is_deeply( $ruleapp5->GetItems(), [ @groups[ 0 .. 4 ] ], q{Items, ruleapp5} );
is_deeply( $ruleapp5->GetStates(), [ 0, 1, 0, 1, 0 ] );


my $ruleapp6 = $rule4->AttemptApplication(
    {   start => $groups[1],
        terms => 5,
        direction  => $DIR::RIGHT
    }
);
is_deeply( $ruleapp6->GetItems(), [ @groups[ 1 .. 5 ] ], q{Correct start state chosen} );
is_deeply( $ruleapp6->GetStates(), [ 1, 0, 1, 0, 1 ], 'states ok' );

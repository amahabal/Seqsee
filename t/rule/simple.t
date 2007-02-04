use strict;
use blib;
use Test::Seqsee;
plan tests => 29;

use Class::Multimethods;
use SRule;
use SRuleApp;
multimethod q{find_reln};
multimethod q{createRule};

SWorkspace->init( { seq => [qw( 1 2 3 4 5 6 7 8 9)] } );

my $WSO_ra = find_reln( $SWorkspace::elements[0], $SWorkspace::elements[1] );
$WSO_ra->insert();

my $WSO_rb = find_reln( $SWorkspace::elements[1], $SWorkspace::elements[2] );
$WSO_rb->insert();

my $rule1 = createRule($WSO_ra);
my $rule2 = createRule($WSO_rb);

isa_ok $rule1, "SRule";
is $rule1, $rule2, "Memoized!";

my $ruleapp1 = $rule1->CreateApplication(
    {
        start     => $SWorkspace::elements[3],
        state     => 0,
        direction => $DIR::RIGHT,
    }
);

is_deeply(
    $ruleapp1->GetItems(),
    [ $SWorkspace::elements[3] ],
    q{Items, ruleapp1}
);
is_deeply( $ruleapp1->GetStates(), [0] );

lives_ok { $ruleapp1->ExtendRight() } "Extending ruleapp right";
is_deeply(
    $ruleapp1->GetItems(),
    [ $SWorkspace::elements[3], $SWorkspace::elements[4] ],
    q{Items, ruleapp1}
);
is_deeply( $ruleapp1->GetStates(), [ 0, 0 ] );

lives_ok { $ruleapp1->ExtendLeft() } "Extending ruleapp left";
is_deeply(
    $ruleapp1->GetItems(),
    [
        $SWorkspace::elements[2], $SWorkspace::elements[3],
        $SWorkspace::elements[4]
    ],
    q{Items, ruleapp1}
);
is_deeply( $ruleapp1->GetStates(), [ 0, 0, 0 ] );

my $ruleapp2 = $rule1->AttemptApplication(
    {
        start     => $SWorkspace::elements[0],
        terms     => 4,
        direction => $DIR::RIGHT,
    }
);
is_deeply(
    $ruleapp2->GetItems(),
    [ @SWorkspace::elements[ 0, 1, 2, 3 ] ],
    q{Items, ruleapp2}
);
is_deeply( $ruleapp2->GetStates(), [ 0, 0, 0, 0 ] );
ok( $ruleapp2->ExtendRight(3), );
is_deeply(
    $ruleapp2->GetItems(),
    [ @SWorkspace::elements[ 0 .. 6 ] ],
    q{Items, ruleapp2}
);
is_deeply( $ruleapp2->GetStates(), [ (0) x 7 ] );
ok( not( $ruleapp2->ExtendLeft() ), );
is_deeply(
    $ruleapp2->GetItems(),
    [ @SWorkspace::elements[ 0 .. 6 ] ],
    q{Items, ruleapp2}
);
is_deeply( $ruleapp2->GetStates(), [ (0) x 7 ] );

my $ruleapp3 = $rule1->AttemptApplication(
    {
        start     => $SWorkspace::elements[2],
        terms     => 3,
        direction => $DIR::RIGHT,
    }
);
is_deeply(
    $ruleapp3->GetItems(),
    [ @SWorkspace::elements[ 2, 3, 4 ] ],
    q{Items, ruleapp3}
);
ok( not( $ruleapp3->ExtendLeft(4) ), );
is_deeply(
    $ruleapp3->GetItems(),
    [ @SWorkspace::elements[ 2, 3, 4 ] ],
    q{Unrolled fine!}
);

SWorkspace->init( { seq => [qw( 1 2 1 2 1 2 1 2 1 2 1 2)] } );

my $WSO_rc = find_reln( $SWorkspace::elements[0], $SWorkspace::elements[1] );
$WSO_rc->insert();

my $WSO_rd = find_reln( $SWorkspace::elements[1], $SWorkspace::elements[2] );
$WSO_rd->insert();

my $rule3 = createRule($WSO_rd);
my $rule4 = createRule( $WSO_rc, $WSO_rd );

my $ruleapp4 =
  $rule3->AttemptApplication(
    { start => $SWorkspace::elements[1], terms => 3, direction => $DIR::RIGHT }
  );
ok( not($ruleapp4), );

$ruleapp4 =
  $rule3->AttemptApplication(
    { start => $SWorkspace::elements[1], terms => 2, direction => $DIR::RIGHT } );
is_deeply(
    $ruleapp4->GetItems(),
    [ @SWorkspace::elements[ 1, 2 ] ],
    q{Items, ruleapp4}
);
is_deeply( $ruleapp4->GetStates(), [ 0, 0 ] );

my $ruleapp5 = $rule4->AttemptApplication(
    {
        start      => $SWorkspace::elements[0],
        terms      => 5,
        from_state => 1,
        direction  => $DIR::RIGHT,
    }
);
ok( not($ruleapp5), );
$ruleapp5 = $rule4->AttemptApplication(
    {
        start      => $SWorkspace::elements[0],
        terms      => 5,
        from_state => 0,
        direction  => $DIR::RIGHT,
    }
);
is_deeply(
    $ruleapp5->GetItems(),
    [ @SWorkspace::elements[ 0 .. 4 ] ],
    q{Items, ruleapp5}
);
is_deeply( $ruleapp5->GetStates(), [ 0, 1, 0, 1, 0 ] );

my $ruleapp6 = $rule4->AttemptApplication(
    {
        start => $SWorkspace::elements[1],
        terms => 5,
        direction => $DIR::RIGHT,
    }
);
is_deeply(
    $ruleapp6->GetItems(),
    [ @SWorkspace::elements[ 1 .. 5 ] ],
    q{Correct start state chosen}
);
is_deeply( $ruleapp6->GetStates(), [ 1, 0, 1, 0, 1 ] );

# my $rule1 = createRule($WSO_ra);
# my $next_object = $rule1->apply($SWorkspace::elements[4]);
# isa_ok $next_object, "SElement";

# Damn! looks like I need some notion of hypotheticals (specifically, if the rule is
# stateful (as when we are dealing with a bouncing doubler), the applying a rule at a point makes
# sense only if we are willing to say "If I am going forward, then applying the rule yields...")
# I also need some notion of "choice I made", with other choices somehow remembered (specifically,
# in extending 1 2 3 when the following thing is 4 4 4, things can be extended in at least 2 ways:
# 4, or 444 being next. Even 44 could sometimes be a choice. But the path not taken cannot be
# totally lost.
# A third tough problem relating to self watching involves being able to "undo" large chunks of
# work, to set a failsafe point before trying dangerous things.

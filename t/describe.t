use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 25; }


my $mtn = $S::mountain;
my $ascending = $S::ascending;
my $descending = $S::descending;
my $double = $S::double;

{
  my $bo = SBuiltObj->new_deep(1, 2, 3);
  my $bindings = $bo->describe_as($ascending);
  ok $bindings;
  $bindings->non_blemished_ok();
  $bindings->value_ok(start => 1);
  $bindings->value_ok(end   => 3);

  $bindings = $bo->describe_as($descending);
  ok !$bindings;

  $bindings = $bo->describe_as($mtn);
  ok !$bindings;
}

{
  my $bo = SBuiltObj->new_deep(2, 3, 4, 3, 2);
  my $bindings = $bo->describe_as($mtn);
  ok $bindings;
  $bindings->non_blemished_ok();
  $bindings->value_ok(foot => 2);
  $bindings->value_ok(peak => 4);

  $bindings = $bo->describe_as($descending);
  ok !$bindings;

  $bindings = $bo->describe_as($ascending);
  ok !$bindings;
}


{
  my $bo = SBuiltObj->new_deep(2, 3, [4, 4], 3, 2);
  my $bindings = $bo->describe_as($mtn);
  ok $bindings;
  $bindings->blemished_ok();
  $bindings->value_ok(foot => 2);
  $bindings->value_ok(peak => 4);
  $bindings->where_ok([2]);
  $bindings->starred_ok([4]);
  $bo->add_cat($mtn, $bindings);

  ok $bo->blemish_positions_may_be( $bindings, [SPos->new(3)] );
  ok $bo->blemish_positions_may_be( $bindings, [SPos->new("peak")]);

  ok !$bo->blemish_positions_may_be( $bindings, [SPos->new(2)] );
  ok !$bo->blemish_positions_may_be( $bindings, [SPos->new("foot")]);

  ok $bo->blemish_type_may_be( $bindings, [$double]);

  $bindings = $bo->describe_as($descending);
  ok !$bindings;

  $bindings = $bo->describe_as($ascending);
  ok !$bindings;
}



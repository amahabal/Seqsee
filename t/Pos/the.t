use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 1; }

my $double = $S::double;
my $ascending = $S::ascending;
my $pos_asc = SPos->new_the( $ascending );

my $another_composite = SBuiltObj->new_deep([1, 2, 3], [2, 3, 2], [5, 6]);
throws_ok {$another_composite->apply_blemish_at( $double, $pos_asc )}
  "SErr::Pos::MultipleNamed";

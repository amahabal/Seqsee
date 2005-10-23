use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 1; }

my $double = $S::DOUBLE;
my $ascending = $S::ASCENDING;
my $pos_asc = SPos->new_the( $ascending );

my $another_composite = SObject->create( [1,2,3], [2,3,2], [5,6]);

throws_ok {$another_composite->apply_blemish_at( $double, $pos_asc )}
  "SErr::Pos::MultipleNamed";

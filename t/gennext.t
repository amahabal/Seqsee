use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 13; }

use MyFilter;
use SCat::ascending;
use SCat::descending;
use SCat::mountain;
use SCat::number;
use SUtil;

sub throws_ok_gennext{
  my ($o1, $o2) = @_;
  eval { gennext($o1, $o2) };
  isa_ok $@, "Exception::Class";
}

sub ok_gennext {
  my $o1 = shift;
  my $o2 = shift;
  my $next;
  eval { $next = gennext($o1, $o2) };
  if ($@) {
    ok 0, "gennext died!";
  } else {
    if ($next->has_structure_one_of(@_)) {
      ok 1, "has structure one of";
    } else {
      ok 0, "has structure one of";
    }
  }
}

SKIP: {

skip "unimplemented", 13;

INTEGERS:
{
  my $bo_7 = new SBuiltObj(7);
  my $bo_8 = new SBuiltObj(8);
  my $bo_9 = new SBuiltObj(9);

  ok_gennext($bo_8, $bo_8, $bo_8);
  ok_gennext($bo_7, $bo_8, [9]);
  ok_gennext($bo_9, $bo_8, [7]);

  throws_ok_gennext($bo_7, $bo_9);
}

ASCENDING_UNBLEMISHED:
{
  my $bo_3_7 = $SCat::ascending::ascending->build(start => 3, end => 7);
  my $bo_3_8 = $SCat::ascending::ascending->build(start => 3, end => 8);
  my $bo_2_7 = $SCat::ascending::ascending->build(start => 2, end => 7);
  my $bo_3_6 = $SCat::ascending::ascending->build(start => 3, end => 6);
  my $bo_2_6 = $SCat::ascending::ascending->build(start => 2, end => 6);
  my $bo_5_9 = $SCat::ascending::ascending->build(start => 5, end => 9);

  ok_gennext $bo_3_7, $bo_3_7, $bo_3_7;
  ok_gennext $bo_3_7, $bo_2_7, [1..7];
  ok_gennext $bo_3_7, $bo_3_8, [3..9];
  ok_gennext $bo_3_7, $bo_3_6, [3..5];

  throws_ok_gennext $bo_3_7, $bo_5_9;
}

ASCENDING_BLEMISHED:
{
  my $cat      = $SCat::ascending::ascending;
  my $blemish  = $SBlemish::double::double;
  
  my $bo_2_5_none   = $cat->build(start => 2, end => 5);
  my $bo_2_5_second  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 2,    end     => 5,
					 pos   => SPos->new(1)
					);
  my $bo_2_5_third  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 2,    end     => 5,
					 pos   => SPos->new(2)
					);
  my $bo_2_5_first  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 2,    end     => 5,
					 pos   => SPos->new(0)
					);
  
  my $bo_1_5_second  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 1,    end     => 5,
					 pos   => SPos->new(1)
					);
  my $bo_1_5_third  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 1,    end     => 5,
					 pos   => SPos->new(2)
					);
  my $bo_1_5_first  = generate_blemished(cat   => $cat, blemish => $blemish,
					 start => 1,    end     => 5,
					 pos   => SPos->new(0)
					);
  
  ok_gennext $bo_1_5_first, $bo_1_5_first,  $bo_1_5_first;
  ok_gennext $bo_1_5_first, $bo_1_5_second, $bo_1_5_third;
  ok_gennext $bo_1_5_first, $bo_2_5_first,  [[3, 3], 4, 5];
  ok_gennext $bo_1_5_first, $bo_2_5_second, [3, 4, [5, 5]];

}
}

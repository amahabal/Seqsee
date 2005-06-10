use blib;
use Test::Seqsee;
BEGIN { plan tests => 11; }

use SCat;
use SCat::mountain;
use SBlemish;
use SBlemish::double;
use SPos;

my $cat = $SCat::mountain::mountain;
my $blemish = $SBlemish::double::double;

my $pos2 = new SPos 2;
my $pos10 = new SPos 10;
my $pos_peak = new SPos "peak";

dies_ok { $cat->derive_blemished() };
dies_ok { $cat->derive_blemished(blemish => "foo") };
dies_ok { $cat->derive_blemished(blemish => $blemish, position => "foo") };
 

my $blemished2;
lives_ok { $blemished2 = $cat->derive_blemished(blemish  => $blemish,
						position => $pos2
					       )};

isa_ok($blemished2, "SCat");

BUILDING: {
  my $bo;
  dies_ok { $blemished2->build() };
  $bo = $blemished2->build(foot => 3, peak => 6);
  isa_ok $bo, "SBuiltObj";
  $bo->structure_ok([3, [4,4], 5, 6, 5, 4, 3]);

  $bo = $blemished2->build(foot => 5, peak => 6);
  isa_ok $bo, "SBuiltObj";
  $bo->structure_ok([5, [6, 6], 5]);

  # XXX in general, when we run into trouble, it is not quite clear what needs to be done. But there should be a way to specify the need... until I figure out how, I'll just die
  dies_ok { $blemished2->build(foot => 5, peak => 5) };
}

INSTANCER: {
  1;
}

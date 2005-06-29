use blib;
use strict;
use Test::Seqsee;
BEGIN { plan tests => 19 }

use SBuiltObj;
use SCat;
use SPos;
use SCat::mountain;

#use MyFilter;

my $mtn = $SCat::mountain::mountain;
my $bo  = $mtn->build( { foot => 3, peak => 5 } );

ok UNIVERSAL::isa( "SPos::Global",           "SPos" );
ok UNIVERSAL::isa( "SPos::Global::Absolute", "SPos::Global" );
ok UNIVERSAL::isa( "SPos::Named",            "SPos" );
Absolute: {
  my @objs;

  my $pos_1 = new SPos(1);
  isa_ok $pos_1, "SPos::Global";
  # isa_ok $pos_1->{finder}, "SPosFinder";
  @objs = $bo->find_at_position($pos_1);
  ok( @objs == 1 );
  $objs[0]->structure_ok( [3] );

  my $pos_1_copy = new SPos(1);
  is $pos_1, $pos_1_copy;


  my $pos_m2 = new SPos(-2);
  isa_ok $pos_m2, "SPos::Global";
  #isa_ok $pos_m2->{finder}, "SPosFinder";
  @objs = $bo->find_at_position($pos_m2);
  ok( @objs == 1 );
  $objs[0]->structure_ok( [4] );

  my $pos_m6 = new SPos(-6);
  isa_ok $pos_m6, "SPos::Global";
  #isa_ok $pos_m6->{finder}, "SPosFinder";
  throws_ok { @objs = $bo->find_at_position($pos_m6) } "SErr::Pos::OutOfRange";
}

Named: {
  my @objs;
  my $pos_peak      = new SPos("peak");
  my $pos_peak_copy = new SPos("peak");
  is $pos_peak, $pos_peak_copy;

  isa_ok $pos_peak, "SPos::Named";
  my $cat_random = new SCat({});
  my $cat_arbit = new SCat({});

  $pos_peak->install_finder(
    cat    => $cat_random,
    finder => new SPosFinder({
			      multi => 0,
			      sub   => sub { return [2] }
			      }
    )
  );

  $pos_peak->install_finder(
    cat    => $cat_arbit,
    finder => new SPosFinder({
			      multi => 0,
			      sub   => sub { return [3] }
			      }
    )
  );

  # Next test commented out: its fishing for internal details
  #isa_ok $pos_peak->{find_by_cat}{$cat_arbit}, "SPosFinder";

  my $bo_arbit = new SBuiltObj( { items => [ 1, 2, 3, 4 ] } );
  $bo_arbit->add_cat( $cat_arbit, {} );

  my $bo_random = new SBuiltObj( { items => [ 1, 2, 3, 4 ] } );
  $bo_random->add_cat( $cat_random, {} );

  @objs = $bo_arbit->find_at_position($pos_peak);
  ok( @objs == 1 );
  $objs[0]->structure_ok( [4] );

  @objs = $bo_random->find_at_position($pos_peak);
  ok( @objs == 1 );
  $objs[0]->structure_ok( [3] );

  $bo_arbit->add_cat( $cat_random, {} );
  throws_ok { @objs = $bo_arbit->find_at_position($pos_peak) }
    "SErr::Pos::MultipleNamed";
}

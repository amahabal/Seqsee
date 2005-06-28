use blib;
use Test::Seqsee;
BEGIN { plan tests => 8; }

use SBuiltObj;
use SCat;

my $bo = new SBuiltObj( { items => [ 1, 2, 3 ] } );
dies_ok { $bo->add_cat(); } "add_cat needs arguments";
dies_ok { $bo->add_cat("foo") } "add_cat first argument must be isa SCat";
my $cat1 = new SCat(
  {
    attributes     => [],
    builder        => 1,
    guesser_pos_of => {},
    guesser_of     => {},

  }
);
my $cat2 = SCat->new(
  {
    attributes     => [qw/start/],
    builder        => 1,
    guesser_pos_of => {},
    guesser_of     => {},
  }

);
lives_ok { $bo->add_cat( $cat1, {} ) } "add_cat lives okay with cat arg";
dies_ok { $bo->add_cat( $cat2, { foo => 3 } ) }
  "if bindings present, they must be attributes";
lives_ok { $bo->add_cat( $cat2, { start => 3 } ) }
  "add_cat okay if bindings really are attributes";

my @cats = sort $bo->get_cats();
cmp_deeply( \@cats, [ sort( $cat1, $cat2 ) ] );
undef_ok( $bo->get_cat_bindings($cat2)->{foo} );
is( $bo->get_cat_bindings($cat2)->{start}, 3 );


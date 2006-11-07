use strict;
use blib;
use Test::Seqsee;
plan tests => 8; 

my $bo = SObject->create(1,2,3);

dies_ok { $bo->add_category() }  "add_category needs arguments";
dies_ok { $bo->add_category("foo") } "add_category first argument must be isa SCat::OfObj";
my $cat1 = $S::ASCENDING;
my $cat2 = $S::MOUNTAIN;
my $cat3 = $S::DESCENDING;

lives_ok { $bo->add_category( $cat1, SBindings->create({}, {}, $bo) ) } 
    "add_cat lives okay with cat arg";
lives_ok { $bo->add_category( $cat2, SBindings->create({}, {}, $bo) ) } 
    "add_cat lives okay with cat arg";

my @cats = sort @{ $bo->get_categories() };
cmp_deeply( \@cats, [ sort( $cat1, $cat2 ) ] );

my $in_cat1 = $bo->is_of_category_p($cat1)->[0];
my $in_cat2 = $bo->is_of_category_p($cat2)->[0];
my $in_cat3 = $bo->is_of_category_p($cat3)->[0];

ok($in_cat1);
ok($in_cat2);
ok(!$in_cat3);



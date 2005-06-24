use blib;
use Test::Seqsee;

BEGIN { plan tests => 23; }

use SBuiltObj;
use SBindings;
use SCat;

use SBlemish;
use SUtil;
use MyFilter;
use Perl6::Subs;

my $bl;

dies_ok { $bl = new SBlemish } "SBlemished is composed.. need data!";

my $blemisher =  sub {
  my ($self, %args) = @_;
  my $what = delete $args{what};
  my $new_obj = new SBuiltObj;
  $new_obj->set_items([$what, $what]);
  $new_obj;
};

my $guesser = {
	       what => sub($self, $bo) { 
		 my $ret = $bo->items()->[0];
		 $ret;
	       }
	      };
my $guesser_flat = {
		    what => sub($self, *@bo) { 
		      #print "#\tsignature checked okay", scalar(@bo), "\n";
		      return undef if (@bo % 2);
		      my @parts = @bo[0 .. (@bo/2) - 1];
		      #print "#\tparts are: @parts\n";
		      return SBuiltObj->new({items => \@parts});
		    }
		   };

lives_ok { $bl = new SBlemish({blemisher    => $blemisher,
			       empty_ok     => 1,
			       empty_what   => new SBuiltObj(),
			       att          => new Set::Scalar(),
			       guesser_of      => $guesser,
			       guesser_flat_of => $guesser_flat,
			       guesser_pos_of  => {},
			       builder => 1,
			      }
			      ); };

isa_ok $bl,                  "SBlemish";
isa_ok $bl,                  "SCat";
    ok $bl>get_blemished;
isa_ok $bl->get_blemisher,        "CODE";
isa_ok $bl->get_instancer,        "CODE";
isa_ok $bl->get_instancer_flat,   "CODE";


#diag "TESTING BLEMISHER";
my $bo = SBuiltObj->new({items => [1, 2, 3]});
my $blemished = $bl->blemish($bo);
$blemished->structure_ok([[1, 2, 3], [1, 2, 3]]);
instance_of_cat_ok $blemished, $bl;
my $blemished_cat_hash = $blemished->get_blemish_cats();
ok exists $blemished_cat_hash->{$bl}; 

#diag "TESTING AUTO-GENERATED FUNCTIONS FOR INSTANCE";
my $maybe_blemished = SBuiltObj->new_deep([1, 2, 3], [1, 2, 3]);
my $guess_what = $bl->guess_attribute($maybe_blemished, "what");
$guess_what->structure_ok([1, 2, 3]);
my $bindings = $bl->is_instance($maybe_blemished);
ok $bindings, "The deep object was recognized as an instance";
isa_ok $bindings->{what}, "SBuiltObj";
$bindings->{what}->structure_ok([1, 2, 3]);

my $unblemished = $bl->unblemish($maybe_blemished);
$unblemished->structure_ok([1, 2, 3]);

#diag "TESTING AUTO-GENERATED FUNCTIONS FOR NON-INSTANCE";
my $maybe_blemished_but_not = SBuiltObj->new_deep([[1, 2, 3], [1, 2, 3, 4]]);
$bindings = $bl->is_instance($maybe_blemished_but_not);
undef_ok $bindings;
$unblemished = $bl->unblemish($maybe_blemished_but_not);
undef_ok $unblemished;

#diag "TESTING AUTO-GENERATED FUNCTIONS FOR FLAT INSTANCE";
my $maybe_blemished_flat = SBuiltObj->new({items => [1, 2, 3, 1, 2, 3]});
#diag @maybe_blemished_flat.items;
$bindings = $bl->is_instance(@{$maybe_blemished_flat->items});
ok $bindings;
isa_ok $bindings->{what}, "SBuiltObj";
$bindings->{what}->structure_ok([1, 2, 3]);
# The following is nonsense
#$unblemished = $bl->unblemish($maybe_blemished_flat);
#$unblemished->structure_ok([1, 2, 3]);

#diag "TESTING AUTO-GENERATED FUNCTIONS FOR FLAT NON-INSTANCE";
my $maybe_blemished_flat_but_not = 
  SBuiltObj->new({items => [1, 2, 3, 5, 1, 2, 3, 4]});
$bindings = $bl->is_instance(@{$maybe_blemished_flat_but_not->items});
undef_ok $bindings;
$unblemished = $bl->unblemish($maybe_blemished_flat_but_not);
undef_ok $unblemished;




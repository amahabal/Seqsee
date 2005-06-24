package SCat::mountain;
use SCat;
use SPos;
use Perl6::Subs;

our $mountain = new SCat;
my $cat = $mountain;

$cat->add_attributes(qw/foot peak/);
$cat->{builder} = sub ($self, +$foot is required, +$peak is required){
  my $ret = new SBuiltObj;
  $ret->set_items([$foot .. $peak, 
		   reverse($foot .. $peak - 1)]);
  $ret->add_cat($cat, { foot => $foot, peak => $peak });
  $ret;
};


$cat->install_position_finder
  ('peak',
   sub {
     my $bo = shift;
     my $items = $bo->items;
     my $count = scalar(@$items);
     my $ret = ($count - 1) / 2;
     return [ $ret ];
   },
   multi => 0,
  );

$cat->{guesser_pos} = { foot => 0 };
$cat->{empty_ok} = 1;
$cat->compose();


1;

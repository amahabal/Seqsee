package SBlemish::double;
use SBlemish;
use SBindings;
use Perl6::Subs;
use MyFilter;

my $blemisher = sub {
  my ($self, %args) = @_;
  my $what = delete $args{what};
  my $new_obj = new SBuiltObj;
  $new_obj->set_items([$what, $what]);
  $new_obj;
};

my $guesser = {
	       what => sub ($self, $bo){
		 $bo->items()->[0];
	       },
	      };

my $guesser_flat = {
		    what => sub($self, *@bo){
		      return undef if @bo % 2;
		      return SBuiltObj->new( @bo[0.. (@bo / 2) - 1]);
		    },
		   };


our $double = new SBlemish({att           => new Set::Scalar(),
			    blemisher     => $blemisher,
			    empty_ok      => 1,
			    empty_what    => new SBuiltObj(),
			    guesser_of       => $guesser,
			    guesser_flat_of  => $guesser_flat,
			    builder => 1, # will get reset later
			    guesser_pos_of => {}
			   }
			  );
my $blemish = $double;

1;

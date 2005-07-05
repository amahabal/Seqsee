package SCat::mountain;
use strict;
use Carp;

our $mountain = new SCat(
  { name => "mountain",
    attributes => [qw{foot peak}],
    builder    => sub {
      ( @_ == 2 ) or confess "mountain builder takes only two args";
      my ( $self, $options_ref ) = @_;
      my $foot = $options_ref->{foot} or croak "Need foot";
      my $peak = $options_ref->{peak} or croak "Need peak";
      my $ret  = new SBuiltObj;
      $ret->set_items( [ $foot .. $peak, reverse( $foot .. $peak - 1 ) ] );
      $ret->add_cat( $self, { foot => $foot, peak => $peak } );
      $ret;
    },
    empty_ok       => 1,
    guesser_pos_of => { foot => 0 },
  }
);

my $cat = $mountain;

$cat->install_position_finder(
  'peak',
  sub {
    my $bo    = shift;
    my $items = $bo->items;
    my $count = scalar(@$items);
    my $ret   = ( $count - 1 ) / 2;
    return [$ret];
  },
  0
);
#print "mountain is $mountain\n";
$cat->compose();

1;

package SCat::mountain;
use strict;
use SCat;
use SPos;
use Carp;

our $mountain = new SCat(
  {
    attributes => [qw{foot peak}],
    builder    => sub {
      ( @_ == 2 ) or confess "mountain builder takes only two args";
      my ( $self, $options_ref ) = @_;
      my $foot = $options_ref->{foot} or die "Need foot";
      my $peak = $options_ref->{peak} or die "Need peak";
      my $ret  = new SBuiltObj;
      $ret->set_items( [ $foot .. $peak, reverse( $foot .. $peak - 1 ) ] );
      $ret->add_cat( $self, { foot => $foot, peak => $peak } );
      $ret;
    },
    empty_ok       => 1,
    guesser_pos_of => { foot => 0 },
    guesser_of     => {},
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

$cat->compose();

1;

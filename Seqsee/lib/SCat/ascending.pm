#####################################################
#
#    Package: SCat::ascending
#
#####################################################
#   Sets up the category "ascending"
#####################################################

package SCat::ascending;
use strict;
use Carp;
use base qw{};

my $builder = sub {
  my ( $self, $args_ref ) = @_;
  my $params_count;
  for (qw{start end length}) {
    $params_count++ if exists $args_ref->{$_};
  }
  confess 'Too few params' if $params_count < 2;
  my ( $start, $end );
  $start =
  exists( $args_ref->{start} )
  ? $args_ref->{start}
  :$args_ref->{end} - $args_ref->{length} + 1;
  $end =
  exists( $args_ref->{end} )
  ? $args_ref->{end}
  :$args_ref->{start} + $args_ref->{length} - 1;
  $args_ref->{start}  ||= $start;
  $args_ref->{end}    ||= $end;
  $args_ref->{length} ||= $end - $start + 1;
  my $start_mag = ref($start) ? $start->get_mag() :$start;
  my $end_mag   = ref($end)   ? $end->get_mag()   :$end;
  my $ret = SObject->create( $start_mag .. $end_mag );
  $ret->add_category( $self, SBindings->create( {}, $args_ref, $ret ) );
  $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
  return $ret;
};

our $ascending = SCat::OfObj::Std->new(
  {
    name        => q{ascending},
    to_recreate => q{$S::ASCENDING},
    builder     => $builder,

    to_guess => [qw/start end/],
    att_type => {
      start => q{int},
      end   => q{int},
    },
    positions => {
      start => SPos->new(1),
      end   => SPos->new(-1),
    },
    sufficient_atts => {
      'end:start'        => 1,
      'length:start'     => 1,
      'end:length'       => 1,
      'end:length:start' => 1,
    },
  }
);

1;


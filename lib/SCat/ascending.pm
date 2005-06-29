package SCat::ascending;
use strict;
use Carp;
use SCat;

our $ascending = new SCat(
  {
    attributes => [qw{start end}],
    builder    => sub {
      my ( $self, $args_ref ) = @_;
      croak "need start" unless $args_ref->{start};
      croak "need end"   unless $args_ref->{end};
      my $ret = new SBuiltObj;
      $ret->set_items( [ $args_ref->{start} .. $args_ref->{end} ] );
      $ret->add_cat( $self, $args_ref );
      $ret;
    },
    empty_ok => 1,
    guesser_pos_of => { start => 0, end => -1 },
  }
);
my $cat = $ascending;

$cat->compose();

1;

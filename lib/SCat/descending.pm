package SCat::descending;
use strict;
use Carp;

our $descending = new SCat(
  { name => "descending",
    builder => sub {
      my ( $self, $args_ref ) = @_;
      croak "need start" unless $args_ref->{start};
      croak "need end"   unless $args_ref->{end};
      my $ret = new SBuiltObj;
      $ret->set_items( [ reverse( $args_ref->{end} .. $args_ref->{start} ) ] );
      $ret->add_cat( $self, $args_ref );
      $ret;
    },
    empty_ok => 1,
    guesser_pos_of => { start => 0, end => -1 },
  }
);
my $cat = $descending;

$cat->add_attributes(qw/start end/);

$cat->compose();

1;

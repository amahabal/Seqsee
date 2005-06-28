package SPos;
use strict;

# use MyFilter;

use SPosFinder;
use SPos::Global;
use SPos::Global::Absolute;
use SPos::Named;

use Carp;
use Memoize;
memoize('new');

sub new {
  my $package = shift;
  my $what    = shift;
  my %args    = @_;
  die "A position must have a number or a string as the first argument to new."
    unless $what;
  my $self;

  if ( $what =~ m/^-?\d+$/ ) {
    $self = new SPos::Global::Absolute({index => $what});
  }
  else {
    $self = new SPos::Named({ str => $what });
  }
  $self;
}

1;

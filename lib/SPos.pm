package SPos;
use strict;
use Perl6::Attributes;

use SPosFinder;
use SPos::Global;
use SPos::Global::Absolute;
use SPos::Named;

use Carp;

my %Memoize;

sub new{
  my $package = shift;
  my $what    = shift;
  return $Memoize{$what} if $Memoize{$what};
  my %args    = @_;
  die "A position must have a number or a string as the first argument to new." unless $what;
  my $self; 

  if ($what =~ m/^-?\d+$/) {
    $self =  new SPos::Global::Absolute($what);
  } else {
    $self = new SPos::Named($what);
  }

  $Memoize{$what} = $self;
  $self;
}

1;

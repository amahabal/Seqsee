package SDesc;
use strict;
use Carp;

use SDescs;
use SFascination;

our @ISA = qw{SDescs SFascination};
our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $descriptor, $flag, @labels) = @_;
  croak "Something wrong in arguments to SDesc->new" unless
    ($descriptor and $flag and scalar(@labels) == $flag->{arity});
  bless {
	 descriptor => $descriptor,
	 flag       => $flag,
	 label      => \@labels,
	 descs      => [],
	 str        => "$descriptor##$flag##@labels",
	}, $package;
}

sub similar{
  my ($self, $other) = @_;
  return ($self->{str} eq $other->{str}) ? 1 : 0;
}

1;

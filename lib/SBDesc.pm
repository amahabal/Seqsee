package SBDesc;
use strict;
use Carp;

use SBDescs;
use SFascination;

our @ISA = qw{SBDescs SFascination};
our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $descriptor, $flag, $bflag, @labels) = @_;
  croak "Something wrong in arguments to SBDesc->new" unless
    ($descriptor and $flag and $bflag and scalar(@labels) == $flag->{arity});
  bless {
	 descriptor => $descriptor,
	 flag       => $flag,
	 bflag      => $bflag,
	 label      => \@labels,
	 descs      => [],
	 str        => "$descriptor##$flag##$bflag##@labels",
	}, $package;
}

1;

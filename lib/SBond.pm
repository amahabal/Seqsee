package SBond;
use strict;
use Carp;

use SBDescs;
use SFascination;

our @ISA = qw{SBDescs SFascination};

our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $from, $to) = @_;
  croak "Need from/to arguments" unless ($from and $to);
  bless { from         => $from,
	  to           => $to,
	  descs        => [],
	}, $package;
}

1;

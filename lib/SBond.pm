package SBond;
use strict;
use Carp;

use SBDescs;
use SFascination;
use SThought;

our @ISA = qw{SBDescs SFascination SThought};

our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $from, $to) = @_;
  croak "Need from/to arguments" unless ($from and $to);
  bless { from         => $from,
	  to           => $to,
	  descs        => [],
	  str          => "[$from->{str}--$to->{str}]",
	}, $package;
}

sub contemplate_add_descriptors{
  # XXX dummy implementation
  # maybe the implementation could even stay empty :)
}

sub halo{
  # XXX dummy implementation
  # maybe the implementation could even stay empty :)
}

1;

package SBond;
use strict;
use Carp;

use SBDescs;
use SFascination;
use SThought;
use SHistory;

our @ISA = qw{SBDescs SFascination SThought SHistory};

our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $from, $to) = @_;
  croak "Need from/to arguments" unless ($from and $to);
  my $self = bless { from         => $from,
		     to           => $to,
		     descs        => [],
		     str          => "[$from->{str}--$to->{str}]",
		   }, $package;
  $self->history_add('Created', 1);
  $self;
}

sub contemplate_add_descriptors{
  # XXX dummy implementation
  # maybe the implementation could even stay empty :)
}

sub halo{
  # XXX?
  map { $_->{reln} } @{ shift->{descs} }
}

1;

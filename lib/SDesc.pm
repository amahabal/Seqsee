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
	 str        => "$descriptor->{str}##$flag->{str}##@labels",
	 str_sh     => "$flag->{str}##@labels", # for compare()
	}, $package;
}

sub compare{
  my ($desc1, $desc2) = @_;
  #XXX I am assuming that two descriptions are comparable only if their flag+label are the same. Clearly a wrong assumption, but let it stay for the moment...
  return undef unless $desc1->{str_sh} eq $desc2->{str_sh};
  my $relation;
  if ($desc1->{descriptor} eq $desc2->{descriptor}) {
    return SBDesc->new($desc1->{descriptor},
		       $desc1->{flag},
		       $Bflag::both,
		       @{$desc1->{label}}
		      );
  } elsif ($relation = $desc1->{descriptor}->relation($desc2->{descriptor})) {
    return SBDesc->new([$desc1->{descriptor}, 
			$desc2->{descriptor},
			$relation
		       ],

		       [$desc1->{flag}, $desc2->{flag}],
		       $Bflag::change,
		       $desc1->{label}, $desc2->{label},
		      );
  } else {
    return undef;
  }
}

sub similar{
  my ($self, $other) = @_;
  return ($self->{str} eq $other->{str}) ? 1 : 0;
}

1;

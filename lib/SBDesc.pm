package SBDesc;
use strict;
use Carp;

use SBDescs;
use SFascination;
use SFlags;

our @ISA = qw{SBDescs SFascination};
our $FascCallBacks = {};
our @FascOrder     = ();

sub new{
  my ($package, $descriptor, $flag, $bflag, @labels) = @_;
  croak "Something wrong in arguments to SBDesc->new" unless $bflag;
  if ($bflag eq $Bflag::both) {
    croak "Something wrong in arguments to SBDesc->new" unless
      ($descriptor and $flag and scalar(@labels) == $flag->{arity});
    return bless {  
		  descriptor => $descriptor,
		  flag       => $flag,
		  bflag      => $bflag,
		  label      => \@labels,
		  descs      => [],
		  str        => "$descriptor->{str}##$flag->{str}##$bflag->{str}##@labels",
		 }, $package;
  } else {
    #print "Descriptors: @{$descriptor}\n";
    #print "Flags:       @{$flag}\n";
    #print "Lables:      @labels\n";
    croak "Something wrong in arguments to SBDesc->new" unless
      ($descriptor->[0] and $descriptor->[1] and $descriptor->[2]
       and $flag->[0]   and $flag->[1] 
       and scalar(@{$labels[0]}) == $flag->[0]{arity}
       and scalar(@{$labels[1]}) == $flag->[1]{arity}
      );
    return bless {
		  descriptor => $descriptor, # but now ref to a pair of descs
		  flag       => $flag,       # again, a pair
		  bflag      => $bflag,
		  label      => \@labels,
		  descs      => [],
		  str        => "$descriptor->[0]{str}#$descriptor->[1]{str}#$descriptor->[2]##$flag->[0]{str}#$flag->[1]{str}##$bflag->{str}##@{$labels[0]}#@{$labels[1]}",
		 }, $package;
  }
}

1;

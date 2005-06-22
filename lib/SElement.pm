package SElement;
use strict;
use SInt;
use Perl6::Subs;
our @ISA = qw{SInt};

method new($package: $what){
  $what = SInt->new($what) unless ref($what);
  bless $what, $package;
}


1;

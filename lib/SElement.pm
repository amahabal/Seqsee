package SElement;
use strict;
use SInt;
use Perl6::Subs;
use SCat::number;
our @ISA = qw{SInt};

method new($package: $what){
  $what = SInt->new($what) unless ref($what);
  $what->add_cat( $SCat::number::number->build(mag => $what->{'m'} ) );
  bless $what, $package;
}


1;

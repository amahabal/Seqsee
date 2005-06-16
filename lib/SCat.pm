package SCat;
use strict;
use SUtil;
use SBuiltObj;
use Set::Scalar;

use SCat::Derive::assuming;
use SCat::Derive::blemished;

use Perl6::Subs;
use Perl6::Attributes;

our %Cats;

method new($package:){
  my $self = bless {}, $package;
  $.att = new Set::Scalar;
  $self;
}

sub add_attributes{
  my $self = shift;
  $.att->insert(@_);
  $self;
}

method has_attribute($what){
  $.att->has($what);
}

sub build{
  my $self = shift;
  return $.builder->($self, @_);
}

sub is_instance{
  my $self = shift;
  my $builtobj = UNIVERSAL::isa($_[0], "SBuiltObj") ?
    $_[0] : SBuiltObj->new()->set_items(@_);
  return $.instancer->($self, $builtobj);
}


method has_named_position($str){
  return (exists $.position_finder{$str});
}

1;

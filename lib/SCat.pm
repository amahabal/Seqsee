package SCat;
use strict;
use SUtil;
use SBuiltObj;
use Set::Scalar;
use SInstance;

use SCat::Derive::assuming;
use SCat::Derive::blemished;

use Perl6::Subs;
use Perl6::Attributes;

our @ISA = qw{SInstance};
our %Cats;

our %Global_attributes = map { $_ => 1 }
  qw{what};

method new($package:){
  my $self = bless {}, $package;
  $.att = new Set::Scalar;
  $.cats= {};
  $self;
}

sub add_attributes{
  my $self = shift;
  $.att->insert(@_);
  $self;
}

method has_attribute($what){
  $Global_attributes{$what} or $.att->has($what);
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

method is_blemished_cat(){
  $._blemished;
}

method guess_attribute(SBuiltObj $obj, $att){
  my $guesser = $.guesser{$att};
  die "Don't know how to guess attribute $att" unless $guesser;
  return $guesser->($self, $obj);
}

method generate_instancer(){
  die "generate instancer called when instancer already present" 
	if $.instancer;
  my @atts = $.att->members;
  foreach (@atts) {
    die "cannot generate instancer: do not know how to guess attribute $_"
       unless exists $.guesser{$_};
  }
  my $empty_ok = $.empty_ok || 0;
  $.instancer = sub {
	my ($me, $builtobj) = @_;
	if ($builtobj->is_empty) {
	   return SBindings->new() if $empty_ok;
	   return undef;
	}
	my %guess;
	for (@atts){
	  my $guess = $me->guess_attribute($builtobj, $_);
	  return undef unless defined $guess;
	  $guess{$_} = $guess;
	}
	my $guess_built = $me->build(%guess);
	my $bindings = $builtobj->structure_blearily_ok($guess_built);
	if ($bindings) {
	  for (keys %guess) {
	    $bindings->{$_} = $guess{$_};
	  }
	}
	return $bindings;
  };
}

1;

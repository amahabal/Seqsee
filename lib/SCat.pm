package SCat;
use strict;
use SUtil;
use SBuiltObj;
use Set::Scalar;
use SInstance;
use SPos;

use SCat::Derive::assuming;
use SCat::Derive::blemished;

use Perl6::Subs;
use MyFilter;;

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
  my $builtobj = ((@_ == 1) and UNIVERSAL::isa($_[0], "SBuiltObj")) ?
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

method generate_guesser_from_pos($attribute, $pos){
  $.guesser{$attribute} = sub {
	my ($self, $bo) = @_;
	my $obj = $bo->items()->[$pos];
	my @int_vals = $obj->as_int();
	if (@int_vals == 1) { return $int_vals[0]; }
	return undef;
  };
}

method generate_guesser_from_pos_finder($attribute, $finder){
  $.guesser{$attribute} = sub {
	my ($self, $bo) = @_;
	my $range = eval { $finder->($bo) };
	return undef if $@;
	my @objs = $bo->subobj_given_range($range);
	return undef unless (@objs == 1);
	my @int_vals = $objs[0]->as_int();
	if (@int_vals == 1) { return $int_vals[0]; }
	return undef;
   };		    
}

method compose(){
  # The task of this is to tie all loose ends, check sanity etc

  # must have a builder...
  die "New category has no builder!" unless $.builder;
  unless ($.instancer) {
	# Must define what to do with empty objects...
	defined($.empty_ok) or die "No instancer given, and I was not 
told what to do with empty objects, and so I cannot provide my own 
instancer"; 

	# Try and generate guessers for those that are missing
	for ($.att->members) {
	  next if $.guesser{$_}; # already defined
	  unless (exists($.guesser_pos{$_}) or $.position_finder{$_}) {
		die "Cannot generate guesser for $_: need at least a 
guesser_pos";
	  }
	  if (exists $.guesser_pos{$_}){
	    $self->generate_guesser_from_pos($_, $.guesser_pos{$_});
	  } else {
	    $self->generate_guesser_from_pos_finder($_, 
						    $.position_finder{$_});
	  }
	}

	eval { $self->generate_instancer };
	die "No instancer given, and something went wrong when I attempted 
to provide one: $@" if $@;
  }

}

method install_position_finder($name, $sub, +$multi is required){
  SPos->new($name)->install_finder
    ( cat    => $self,
      finder => new SPosFinder( multi => $multi,
				sub => $sub
			      )
    );
  $.position_finder{$name} = $sub; #XXX. SHould use the Finder object!!
}

1;

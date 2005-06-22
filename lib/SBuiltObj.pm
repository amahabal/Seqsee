package SBuiltObj;
use SInt;
use SCat;
use SPos;
use SBlemish;
use SInstance;

use MyFilter;
use Perl6::Subs;

our @ISA = qw{SInstance};

method new($package: *@items){
  my $self = bless {}, $package;
  $self->set_items(@items);
  $.cats = {};
  $self;
}

sub new_deep{
  my $package = shift;
  my $self = bless {}, $package;
  my @items = map { 
    if (ref $_) {
      if (ref($_) eq 'ARRAY') {
	$package->new_deep(@$_);
      } else {
	$_->clone;
      }
    } else {
      SInt->new($_)
    }
  } @_;
  $self->set_items(@items);
  $.cats = {};
  $self;
}

sub set_items{
  my $self = shift;
  $.items = [map { (ref $_) ? $_->clone : SInt->new($_) } @_];
  $self;
}

sub items{
  shift->{items};
}


sub flatten{
  my $self = shift;
  return map { ref $_ ? $_->flatten() : $_ } @.items;
}

method find_at_position($position of SPos){
  my $range = $position->find_range($self);
  return $self->subobj_given_range($range);
}


#method range_given_position($position){
#  return $position->find_range($self);
#}

method subobj_given_range($range){ # Name should be changed!
  my @ret;
  my $items = $.items;
  for (@$range) {
    my $what = $items->[$_];
    die "out of range" if not defined $what;
    push @ret, $what;
  }
  @ret;
}

method get_position_finder($str){ #XXX should really deal with the category of the built object, and I have not dealt with that yet....
  my @cats = $self->get_cats();
  my @cats_with_position = grep { $_->has_named_position($str) } @cats;
  die "Could not find any way for finding the position '$str' for $self" unless @cats_with_position;
  # XXX what if multiple categories have a position of this name??
  return $cats_with_position[0]->{position_finder}{$str};
}

method splice($from, $len, *@rest){
  my $items = $.items;
  splice(@$items, $from, $len, @rest);
  $self;
}

method apply_blemish_at(SBlemish $blemish, $position of SPos where {$_}){ 
	# Assumption: position returns a single item
  $self = $self->clone;
  my $range = $position->find_range($self);
  die "position $position undefined for $self" unless $range;
  # XXX should check that range is contiguous....
  my @subobjs = $self->subobj_given_range($range);
  if (@subobjs >= 2) {
    die "applying blemished over a range longer than 1 not yet implemented";
  }
  my $blemished = $blemish->blemish($subobjs[0]);
  #$blemished->show();
  my $range_start = $range->[0];
  my $range_length = scalar(@$range);
  $self->splice($range_start, $range_length, $blemished);
  #$self->show;
  $self;
}

method clone(){
  my $new_obj = new SBuiltObj;
  my $items = $new_obj->{items};
  foreach (@.items) {
    push (@$items, ref($_) ? $_->clone() : $_ ); 
  }
  while (my($k, $v) = each %.cats) {
    $new_obj->{cats}{$k} = $v; #XXX should I clone this???
  }
  $new_obj;
}

sub show{
  my $self = shift;
  print "Showing the structure of $self:\n";
  print "\nItems:\n";
  foreach (@.items) {
    print "\t$_\n";
    if (ref $_) {
      $_->show_shallow(2);
    }
  }
}

sub show_shallow{
  my ($self, $depth) = @_;
  foreach (@{$self->items}) {
    print "\t" x $depth;
    print "$_\n";
    if (ref $_) {
      $_->show_shallow($depth + 1);
    }
  }
}

sub compare_deep{
  my ($self, $other) = @_;
  return undef if UNIVERSAL::isa($other, "SInt");
  my $self_items  = $self->items;
  my $other_items = $other->items;
  return undef unless scalar(@$self_items) == scalar(@$other_items);
  my $count = scalar(@$self_items);
  for (my $i=0; $i < $count; $i++) {
    return undef unless $self_items->[$i]->compare_deep($other_items->[$i]);
  }
  return 1;
}

sub structure_is{ # To be called by structure_ok
  my ($self, $potential_struct) = @_;
  my @struct_parts = @$potential_struct;
  my @items = @{$self->items};
  unless (scalar(@items) == scalar(@struct_parts)) {
    return 0;
  }
  for (my $i = 0; $i < scalar(@items); $i++) {
    return 0 unless $items[$i]->structure_is($struct_parts[$i]);
  }
  return 1;
}

sub structure_ok{ # ONLY TO BE USED FROM TEST SCRIPTS
  my ($self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok($self->structure_is($potential_struct), $msg);
}


method as_int(){
  return $.items[0]->as_int() if scalar(@.items) == 1;
  my $bl_cats = $self->get_blemish_cats;
  my %ret;
  while (my ($blemish, $what) = each %$bl_cats) {
    my @what_as_int = $what->as_int;
    foreach (@what_as_int) { $ret{$_}++ }
  } 
  return sort { $ret{$b} <=> $ret{$a} } keys %ret;
}

method can_be_as_int($int){
  my @int_vals = $self->as_int();
  for (@int_vals) { return 1 if $_ == $int }
  return undef;
}

method structure_blearily_ok($template){
  my @my_items        = @.items;
  my @template_items  = @{$template->items};
  return undef unless scalar(@my_items) == scalar(@template_items);
  for (my $i = 0; $i < scalar(@my_items); $i++){
    my $my_item = $my_items[$i];
    my $t_item  = $template_items[$i];
    if (UNIVERSAL::isa($t_item, "SInt")) {
      next if $my_item->can_be_as_int($t_item->{'m'});
    } else {
      next if $my_item->structure_blearily_ok($t_item);
    }
    return undef;
  }
  return SBindings->new();
}

method is_empty{
  return 1 unless @.items;
  return 0;
}

1;

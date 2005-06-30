package SBuiltObj;
use strict;
use Carp;
use SInt;
use SCat;
use SPos;
use SBlemish;
use SInstance;

our @ISA = qw{SInstance};

use Class::Std;
my %items : ATTR;

sub BUILD {
  my ( $self, $id, $opts_ref ) = @_;
  $self->set_items( $opts_ref->{items} );
}

=pod

new_deep does a bunch of things...

=cut

sub new_deep {
  my $package = shift;
  my @items = map {
    if ( ref $_ )
    {
      if ( ref($_) eq 'ARRAY' ) {
        $package->new_deep(@$_);
      }
      else {
        $_->clone;
      }
    }
    else {
      SInt->new( { mag => $_ } );
    }
  } @_;
  my $self = $package->new( { items => [@items] } );
  $self;
}

=pod

set_items also does something

=cut

sub set_items {
  my ( $self, $items_ref ) = @_;
  $items{ ident $self } =
    [ map { ( ref $_ ) ? $_->clone : SInt->new( { mag => $_ } ) } @$items_ref ];
  $self;
}

sub items {
  $items{ ident shift };
}

sub flatten {
  my $self = shift;
  return map { $_->flatten() } @{ $items{ ident $self} };
}

sub find_at_position {
  my ( $self, $position ) = @_;
  UNIVERSAL::isa( $position, "SPos" ) or croak "Need SPos";
  my $range = $position->find_range($self);
  return $self->subobj_given_range($range);
}

sub subobj_given_range {
  my ( $self, $range ) = @_;
  my $items_ref = $items{ ident $self };
  my @ret;
  for (@$range) {
    my $what = $items_ref->[$_];
    defined $what or croak "out of range";
    push @ret, $what;
  }
  return @ret;
}

sub get_position_finder {
  my ( $self, $str ) = @_;
  my @cats               = $self->get_cats();
  my @cats_with_position =
    grep { $_->has_named_position($str) } @cats;
  (@cats_with_position == 1)
    or croak "Could not find any way for finding the position '$str' for $self"
      . " Or maybe found too many ways";

  # XXX what if multiple categories have a position of this name??
  return $cats_with_position[0]->{position_finder}{$str};
}

sub splice {
  ( @_ == 4 ) or croak "syntax of splice has changed";
  my ( $self, $from, $len, $rest_ref ) = @_;
  my $items_ref = $items{ ident $self};
  splice( @$items_ref, $from, $len, @$rest_ref );
  return $self;
}

sub apply_blemish_at {
  my ( $self, $blemish, $position ) = @_;
  UNIVERSAL::isa( $blemish,  "SBlemish" ) or croak "need SBlemish";
  UNIVERSAL::isa( $position, "SPos" )     or croak "need SPos";
  $self = $self->clone;
  my $range = $position->find_range($self);
  croak "position $position undefined for $self" unless $range;
  my @subobjs = $self->subobj_given_range($range);
  if ( @subobjs >= 2 ) {
    croak "applying blemished over a range longer than 1 not yet implemented";
  }
  my $blemished = $blemish->blemish( $subobjs[0] );

  #$blemished->show();
  my $range_start  = $range->[0];
  my $range_length = scalar(@$range);
  $self->splice( $range_start, $range_length, [$blemished] );

  #$self->show;
  $self;
}

sub clone {
  my $self    = shift;
  my @items   = map { ref($_) ? $_->clone() : $_ } @{ $items{ ident $self} };
  my $new_obj = new SBuiltObj( { items => \@items } );
  $new_obj->set_cats_hash( $self->get_cats_hash() );
  $new_obj;
}

sub show {
  my $self = shift;
  print "Showing the structure of $self:\n";
  print "\nItems:\n";
  foreach ( @{ $items{ ident $self} } ) {
    print "\t$_\n";
    if ( ref $_ ) {
      $_->show_shallow(2);
    }
  }
}

sub show_shallow {
  my ( $self, $depth ) = @_;
  foreach ( @{ $self->items } ) {
    print "\t" x $depth;
    print "$_\n";
    if ( ref $_ ) {
      $_->show_shallow( $depth + 1 );
    }
  }
}

sub compare_deep {
  my ( $self, $other ) = @_;
  return undef if UNIVERSAL::isa( $other, "SInt" );
  my $self_items  = $self->items;
  my $other_items = $other->items;
  return undef unless scalar(@$self_items) == scalar(@$other_items);
  my $count = scalar(@$self_items);
  for ( my $i = 0 ; $i < $count ; $i++ ) {
    return undef unless $self_items->[$i]->compare_deep( $other_items->[$i] );
  }
  return 1;
}

sub structure_is {    # To be called by structure_ok
  my ( $self, $potential_struct ) = @_;
  my @struct_parts = @$potential_struct;
  my @items        = @{ $self->items };
  unless ( scalar(@items) == scalar(@struct_parts) ) {
    return 0;
  }
  for ( my $i = 0 ; $i < scalar(@items) ; $i++ ) {
    return 0 unless $items[$i]->structure_is( $struct_parts[$i] );
  }
  return 1;
}

sub has_structure_one_of {
  my $self = shift;
  for (@_) {
    my $struct =
      ( UNIVERSAL::isa( $_, "SBuiltObj" ) ) ? $_->get_structure() : $_;
    return 1 if $self->structure_is($struct);
  }
  return 0;
}

sub get_structure {
  my $self = shift;
  [ map { $_->get_structure } @{ $items{ ident $self} } ];
}

sub semiflattens_ok {
  my ( $self, @objects ) = @_;

  # XXX clearly incomplete. Stopgap
  # should flatten only part way
  my @self_flatten = $self->flatten;
  my @other_flatten = map { $_->flatten } @objects;
  return 0 unless @self_flatten == @other_flatten;
  for ( my $i = 0 ; $i < @self_flatten ; $i++ ) {
    return 0 unless $self_flatten[$i] == $other_flatten[$i];
  }
  return 1;
}

sub structure_exactly_ok {
  my ( $self, $other ) = @_;
  return $self->structure_is( $other->get_structure );
}

sub as_int {
  my $self = shift;
  return $items{ ident $self}[0]->as_int()
    if scalar( @{ $items{ ident $self} } ) == 1;

  my $bl_cats = $self->get_blemish_cats;
  my %ret;
  while ( my ( $blemish, $what ) = each %$bl_cats ) {
    my @what_as_int = $what->as_int;
    foreach (@what_as_int) { $ret{$_}++ }
  }
  return sort { $ret{$b} <=> $ret{$a} } keys %ret;
}

sub can_be_as_int {
  my ( $self, $int ) = @_;
  my @int_vals = $self->as_int();
  for (@int_vals) { return 1 if $_ == $int }
  return undef;
}

sub can_be_seen_as_int {
  my ( $self, $int ) = @_;
  # use Smart::Comments;
  ### can_be_seen_as_int: $self, $int
  if (scalar (@{ $items{ident $self} } ) == 1 and
      my $bindings = $items{ident $self}[0]->can_be_seen_as_int($int)
     ) {
    ### Single item: $bindings
    return $bindings;
  }
  my $bl_cats = $self->get_blemish_cats;
  while (my ( $blemish, $what ) = each %$bl_cats ) {
    my $bindings = $what->can_be_seen_as_int( $int );
    ### bindings for $bl_cats: $bindings
    next unless $bindings;
    unless (ref $bindings) {
      $bindings = new SBindings::Blemish;
    }
    $bindings->set_real($what);
    $bindings->set_starred($int);
    return $bindings;
  }
  return;
}

sub structure_blearily_ok {
  my ( $self, $template ) = @_;
  # no Smart::Comments;
  ### $self, $template
  my @my_items       = @{ $items{ ident $self} };
  my @template_items;
  if (ref($template) eq "ARRAY") {
    @template_items = map { SInt->new({mag => $_}) }@$template;
  } else {
    @template_items = @{ $template->items };
  }
  return undef unless scalar(@my_items) == scalar(@template_items);
  ### Item count identical:
  my @blemishes;
  for ( my $i = 0 ; $i < scalar(@my_items) ; $i++ ) {
    my $my_item = $my_items[$i];
    my $t_item  = $template_items[$i];
    ### i,my_items, t_item: $i, $my_item, $t_item
    if ( UNIVERSAL::isa( $t_item, "SInt" ) ) {
      my $bindings = $my_item->can_be_seen_as_int( $t_item->get_mag() );
      ### bindings: $bindings
      if (ref $bindings) {
	$bindings->set_where($i);
	$bindings->set_real($my_item);
	push @blemishes, $bindings;
      }
      next if $bindings;
    }
    else {
      # XXX THIS WILL NOT RETURN BINDINGS CORRECTLY IF TEMPLATE IS NOT SHALLOW
      print "TEMPLATE ITEM NOT AN SINT!!\n";
      next if $my_item->structure_blearily_ok($t_item);
    }
    return undef;
  }
  my $return = new SBindings;
  for (@blemishes) {
    $return->add_blemish($_);
  }
  return $return;
}

sub is_empty {
  my $self = shift;
  return 1 unless @{ $items{ ident $self} };
  return 0;
}

1;

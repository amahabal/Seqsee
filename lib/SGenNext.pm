package SGenNext;
# Currently a fake module, in that I don't know how its going to look like, and it'll change immensely!

use Smart::Comments;

use SCat;
use SCat::mountain;
use SCat::ascending;
use SCat::descending;
use SCat::number;

use SBlemish;
use SBlemish::double;

use SErr;

my @CATEGORIES =
  ( $SCat::descending::descending,
    $SCat::ascending::ascending,
    $SCat::mountain::mountain,
  );

my @BLEMISHES =
  ( $SBlemish::double::double,
  );

my $double = $SBlemish::double::double;

sub main::gennext{
  my ( $object1, $object2 ) = @_;
  ## gennext arguments: $object1, $object2
  my $modifications = changes($object1, $object2);
  SErr->throw("dunno") unless $modifications;
  ## $modifications
  my $new_object = $object2->apply_changes($modifications);
  ## $new_object->show()
  SErr->throw("dunno") unless $new_object;
  return $new_object;
}

sub changes{
  my ( $object1, $object2 ) = @_;
  for my $cat (@CATEGORIES) {
    my $potential_modification = 
      get_change_based_on($cat, $object1, $object2);
    return $potential_modification if $potential_modification;
  }
  return;
}

sub get_change_based_on{
  my ( $cat, $object1, $object2 ) = @_;
  my $bindings1 = $object1->describe_as( $cat );
  return unless $bindings1;
  my $bindings2 = $object2->describe_as( $cat );
  return unless $bindings2;
  # AHA! So at least both are instances of $cat!
  my $value_change = calculate_value_change( $bindings1, $bindings2 );
  return unless $value_change;
  my $location_change = calculate_location_change
    ( $bindings1, $bindings2 );
  return unless $location_change;
  return {cat   => $cat, 
	  value => $value_change,
	  location => $location_change,
	 };
}

sub SBuiltObj::apply_changes{
  my ( $self, $modifications ) = @_;
  my $cat = $modifications->{cat};
  my $val_changes = $modifications->{value};
  my $loc_changes = $modifications->{location};

  my $bindings = $self->describe_as( $cat );
  my $new_values_ref = change_values($bindings, $val_changes);
  return unless $new_values_ref;
  my $basic_object = $cat->build($new_values_ref);

  my $new_loc_ref = change_locations($bindings, $loc_changes);
  return unless $new_loc_ref;
  for (@$new_loc_ref) {
    my $pos = SPos->new($_ + 1);
    $basic_object = $basic_object->apply_blemish_at($double, $pos);
  }

  return $basic_object;
}

sub change_locations{
  my ( $bindings, $loc_changes ) = @_;
  my $where_ref = $bindings->get_where;
  return unless @$where_ref == @$loc_changes;
  my @ret;
  for (my $i = 0; $i < @$where_ref; $i++) {
    my $change = $loc_changes->[$i];
    my $new_loc;
    if ($change eq "succ") {
      $new_loc = $where_ref->[$i] + 1;
    } elsif ($change eq "prev") {
      $new_loc = $where_ref->[$i] - 1;
    } else {
      $new_loc = $where_ref->[$i];
    }
    push @ret,$new_loc;
  }
  return \@ret;
}

sub change_values{
  my ( $bindings, $val_changes ) = @_;
  my @keys = keys %$bindings;
  my $ret = {};
  for my $key (@keys) {
    my $val = $bindings->{$key};
    my $change = $val_changes->{$key};
    my $new_val;
    if ($change eq "succ") {
      $new_val = $val + 1;
    } elsif ($change eq "prev") {
      $new_val = $val - 1;
    } else {
      $new_val = $val;
    }
    $ret->{$key} = $new_val;
  }
  return $ret;
}

sub calculate_location_change{
  my ( $o1, $o2 ) = @_;
  if ($o1->get_blemished) {
    if ($o2->get_blemished) {
      # We need to attempt to get a description of the location too,
      #  and then talk of change. But lets ditch it: 
      # lets just work with absolute position for now
      my $where1_ref = $o1->get_where;
      my $where2_ref = $o2->get_where;
      return unless @$where2_ref == @$where1_ref;
      my @relns;
      for (my $i=0; $i<@$where1_ref; $i++) {
	my $reln = get_relation($where1_ref->[$i], $where2_ref->[$i]);
	return unless $reln;
	push @relns, $reln;
      }
      return \@relns;
    } else {
      return;
    }
  } else {
    if ($o2->get_blemished) {
      return;
    } else {
      return [];
    }
  }
}

sub calculate_value_change{
  my ( $bindings1, $bindings2 ) = @_;
  my %relns;
  my @keys = keys %$bindings1;
  for my $key (@keys) {
    my $val1 = $bindings1->{$key};
    my $val2 = $bindings2->{$key};
    my $reln = get_relation($val1, $val2);
    if ($reln) {
      $relns{$key} = $reln;
      next;
    } else {
      return;
    }
  }
  return \%relns;
}


sub get_relation{
  my ( $o1, $o2 ) = @_;
  # XXX this is a crappy version just to get my feet wet
  return if ref $o1;
  return if ref $o2;
  return "succ" if $o2 == $o1 + 1;
  return "same" if $o2 == $o1;
  return "prev" if $o2 == $o1 - 1;
  return;
}

1;

# New base class for categories of objects.

package SCat::OfObj;
use strict;
use Carp;
use Class::Std;
use base qw{SInstance};
use English qw(-no_match_vars);

#use Smart::Comments;
use Memoize;
use SUtil;
use List::Util qw(sum shuffle);

use Class::Multimethods;
multimethod 'FindTransform';
multimethod 'ApplyTransform';

use overload '~~' => sub { $_[0] eq $_[1] }, fallback => 1;
my %find_transform_of : ATTR(:get<find_transform>);
my %apply_transform_of : ATTR(:get<apply_transform>);

sub BUILD {
  my ( $self, $id, $opts_ref ) = @_;
  $find_transform_of{$id}  = $opts_ref->{find_transform}  || undef;
  $apply_transform_of{$id} = $opts_ref->{apply_transform} || undef;
}

use Class::Multimethods;
multimethod is_instance => qw(SCat::OfObj SObject) => sub {
  my ( $cat, $object ) = @_;
  my $bindings = $cat->Instancer($object) or return;
  $object->add_category( $cat, $bindings );

  return $bindings;
};

sub is_metonyable {
  my ($self) = @_;
  return $S::IsMetonyable{$self};
}

sub find_metonym {
  my ( $cat, $object, $name ) = @_;

  my $finder = $cat->get_meto_finder($name)
  or croak "No '$name' meto_finder installed for category $cat";
  my $bindings = $object->GetBindingForCategory($cat)
  or croak "Object must belong to category";

  my $obj = $finder->( $object, $cat, $name, $bindings );
  ## next line kludgy
  if ( UNIVERSAL::isa( $object, "SAnchored" ) ) {
    $obj->get_starred->set_edges( $object->get_edges );
  }

  return $obj;
}

sub get_squintability_checker {
  my ($self) = @_;

# XXX(Board-it-up): [2006/12/29] Currently just returns No. Should be different for some categories.
  return;
}

sub get_meto_types {
  my ($self) = @_;
  return;
}
memoize('get_meto_types');

sub FindTransformForCat {
  my ( $self, $o1, $o2 ) = @_;
  my $relation_finder = $self->get_find_transform() || \&Default_FindTransform;
  return $relation_finder->( $self, $o1, $o2 );
}

sub ApplyTransformForCat {
  my ( $self, $relation_type, $object ) = @_;
  my $relation_applier = $self->get_apply_transform()
  || \&Default_ApplyTransform;
  return $relation_applier->( $self, $relation_type, $object );
}

sub Default_FindTransform {
  scalar(@_) == 3 or confess "Need 3 arguments for Default_FindTransform";
  my ( $self, $o1, $o2 ) = @_;
  my $cat      = $self;
  my $opts_ref = {};

  confess "Need SObjects, got >>$o1<< >>$o2<<"
  unless ( UNIVERSAL::isa( $o1, 'SObject' )
    and UNIVERSAL::isa( $o2, 'SObject' ) );
  $opts_ref->{first}  = $o1;
  $opts_ref->{second} = $o2;

  # Base category
  my $b1 = $o1->is_of_category_p($cat) or return;
  my $b2 = $o2->is_of_category_p($cat) or return;

  $opts_ref->{category} = $cat;

  ## Base Category found: $cat->as_text

  # Meto mode
  my $meto_mode = $b1->get_metonymy_mode;
  return unless $meto_mode eq $b2->get_metonymy_mode;
  $opts_ref->{meto_mode} = $meto_mode;

  ## Base meto mode found: $meto_mode

  CalculateBindingsChange( $opts_ref, $b1->get_bindings_ref(),
    $b2->get_bindings_ref(), $cat )
  or return;

  ## Binding change: $opts_ref
  if ( $meto_mode->is_metonymy_present() ) {

    # So other stuff is relevant, too!
    if ( $meto_mode->is_position_relevant() ) {    # Position relevant!
      my $rel = FindTransform( $b1->get_position(), $b2->get_position() );
      return unless $rel;
      $opts_ref->{position_reln} = $rel;

      my $meto_type_1 = $b1->get_metonymy_type;
      my $meto_type_2 = $b2->get_metonymy_type;
      $rel = FindTransform( $meto_type_1, $meto_type_2 );
      return unless $rel;
      $opts_ref->{metonymy_reln} = $rel;

      ## Starred relation, unstarred reln, metonymy_reln?
      ## Need to work that out
    }
    else {
      $opts_ref->{position_reln} = '';
    }
  }
  else {
    $opts_ref->{metonymy_reln} = '';
    $opts_ref->{position_reln} = '';
  }

  $opts_ref->{direction_reln} = $Transform::Dir::Same;    #XXX?
  $opts_ref->{slippages} //= {};
  return Transform::Structural->create($opts_ref);
}

sub Default_ApplyTransform {
  my ( $self, $transform, $original_object ) = @_;
  my $reln = $transform;
  my $cat  = $self;
  $original_object // confess "Missing original_object";
  my $object = $original_object->GetEffectiveObject();
  $reln->get_category() eq $self
  or confess "relation_type and base category do not match";

  my $bindings = $object->describe_as($cat) or return;

  # Find the bindings for it.
  my $bindings_ref         = $bindings->get_bindings_ref;
  my $changed_bindings_ref = $reln->get_changed_bindings;
  my $slippages_ref        = $reln->get_slippages();
  my $new_bindings_ref     = {};

  if (%$slippages_ref) {
    for my $att ( keys %$slippages_ref ) {
      my $old_attr = $slippages_ref->{$att} or next;
      my $val = $bindings_ref->{$old_attr};
      if ( exists $changed_bindings_ref->{$att} ) {
        $new_bindings_ref->{$att} =
        ApplyTransform( $changed_bindings_ref->{$att}, $val );
        return unless defined $new_bindings_ref->{$att};
        next;
      }
      $new_bindings_ref->{$att} = $val;
    }
  }
  else {
    while ( my ( $k, $v ) = each %$bindings_ref ) {
      ## $k, $v: $k, $v
      if ( exists $changed_bindings_ref->{$k} ) {
        ## cbr: $changed_bindings_ref->{$k}
        $new_bindings_ref->{$k} =
        ApplyTransform( $changed_bindings_ref->{$k}, $v ) // return;
        next;
      }
      ## handled
      # no change...
      $new_bindings_ref->{$k} = $v;
    }
  }

  my $ret_obj = $cat->build($new_bindings_ref)
  or confess "Failed to build " . $cat->as_text(),
  " from " . join( ', ', keys %$new_bindings_ref );

  # We have not "applied the blemishes" yet, of course
  my $reln_meto_mode   = $reln->get_meto_mode;
  my $object_meto_mode = $bindings->get_metonymy_mode;
  unless ( $reln_meto_mode == $object_meto_mode ) {
    ## reln_meto_mode is not object_meto_mode
    return;
  }

  unless ( $reln_meto_mode == METO_MODE::NONE() ) {

    # Calculate the metonymy type of the new object
    my $new_metonymy_type =
    ApplyTransform( $reln->get_metonymy_reln, $bindings->get_metonymy_type );
    return unless $new_metonymy_type;

    if ( $reln_meto_mode == METO_MODE::ALL() ) {
      $ret_obj = $ret_obj->apply_blemish_everywhere($new_metonymy_type);
    }
    else {

      # If we get here, position is relevant!
      my $new_position =
      ApplyTransform( $reln->get_position_reln, $bindings->get_position );
      return unless $new_position;
      my $blemished;
      eval {
        $blemished =
        $ret_obj->apply_blemish_at( $new_metonymy_type, $new_position );
      };
      return unless $blemished;
      $ret_obj = $blemished;
    }
  }

  $ret_obj->describe_as($cat);
  my $rel_dir = $reln->get_direction_reln() // $Transform::Dir::Same;
  my $obj_dir = $object->get_direction;
  my $new_dir = ApplyTransform( $rel_dir, $obj_dir );

  $ret_obj->set_direction($new_dir);
  $ret_obj->set_group_p(1);
  return $ret_obj;
}

sub CalculateBindingsChange {
  return 1 if CalculateBindingsChange_no_slips(@_);
  return CalculateBindingsChange_with_slips(@_);
}

sub CalculateBindingsChange_no_slips {
  my ( $output_ref, $bindings_1, $bindings_2, $cat ) = @_;
  ##CalculateBindingsChange_no_slips:
  my $changed_ref   = {};
  my $unchanged_ref = {};
  while ( my ( $k, $v1 ) = each %$bindings_1 ) {
    unless ( exists $bindings_2->{$k} ) {
      confess
      "In CalculateBindingsChange_no_slips:: binding for $k missing for second object!";
    }
    my $v2 = $bindings_2->{$k};
    ##  CalculateBindingsChange_no_slips: $k, $v1, $v2
    #if ( $v1 eq $v2 ) {
    #    $unchanged_ref->{$k} = $v1;
    #    next;
    #}
    my $rel = FindTransform( $v1, $v2 );
    ## k, v1, v2, rel: $k, $v1, $v2, $rel
    return unless $rel;
    ### Changed binding seen :$rel
    $changed_ref->{$k} = $rel;
  }
  $output_ref->{changed_bindings}   = $changed_ref;
  $output_ref->{unchanged_bindings} = $unchanged_ref;
  ##  CalculateBindingsChange_no_slips: $output_ref
  return 1;
}

sub CalculateBindingsChange_with_slips {
  my ( $output_ref, $bindings_1, $bindings_2, $cat, $is_reverse ) = @_;

  # An explanation for $is_reverse:
  # For a reln to be valid, it's reverse must be valid too. Thus, a reln
  # between 1 2 3 and 1 as ascending is not desirable, with no way to get back.
  # So I'll also check for reverse, and is_reverse is true if that is what is
  # happening.

  my $changed_ref   = {};
  my $unchanged_ref = {};
  my $slips_ref     = {};
  ##CalculateBindingsChange_with_slips:

  my @attributes = uniq( keys(%$bindings_2), keys(%$bindings_1) );
  LOOP: while ( my ( $k2, $v2 ) = each %$bindings_2 ) {
    for my $k ( shuffle(@attributes) ) {
      ## k2, k: $k2, $k
      my $v = $bindings_1->{$k};
      ## v2, v: $v2, $v
      #if ( $v eq $v2 ) {
      #    $unchanged_ref->{$k2} = $v2;
      #    $slips_ref->{$k2}     = $k;
      #    ## v = v2:
      #    next LOOP;
      #}
      my $rel = FindTransform( $v, $v2 ) // next;
      ## found rel:
      $changed_ref->{$k2} = $rel;
      $slips_ref->{$k2}   = $k;
      next LOOP;
    }
  }
  $output_ref->{changed_bindings}   = $changed_ref;
  $output_ref->{unchanged_bindings} = $unchanged_ref;
  ## checking if atts sufficient: $slips_ref
  return unless $cat->AreAttributesSufficientToBuild( sort keys %$slips_ref );
  ## look sufficient:
  unless ($is_reverse) {
    ## checking reverse:
    return unless CalculateBindingsChange_with_slips(
      {},    # don't care
      $bindings_2,
      $bindings_1,
      $cat,
      1      # is_reverse true
    );
    ## reverse ok :
    #print "H";
  }
  $output_ref->{slippages} = $slips_ref;
  return 1;
}

sub IsNumeric {
  return 0;
}

1;

#####################################################
#
#    Package: SBindings
#
#####################################################
#   Keeps information about how an object is an instance of a particular category.
#
#   I am not completely sure how things here would be represented. Here is the part I am sure about.
#
#   There are two parts to this binding. The first part---called squinting---connects the object to an idealized version. For example, The object [1 2 2 3 4 5] is, for the purposes of the category ascending, connected to the category [1 2 3 4 5]. More details on this later.
#
#   The second part, bindings, maps descriptors to values. Continuing the same example as above, it would have a hashref, containing start => 1, end => 5, length => 5 etc.
#
#   The code is totally out of sync with this description, currently.
#
#  Bindings:
#    This is just a hashref stored in %bindings_of_of
#
#  Squinting:
#    Squinting is further divided into two parts; There is the raw aspect of squinting: the actual metonyms in action here, and there is the "story" aspect.
#
#  Squinting, Raw:
#     Consider the case of [1 1 2 2 3 4 4] being seen as [1 2 3 4].
#
#     Raw squinting will note the three metonyms involved here; These will be stored as a hash ref, indexed by actual index. So %squinting_raw_of{$id} is a hashref, which will look like: { 0 => $meto, 1 => $meto, 3 => $meto }
#
#   Squinting, Story:
#      This is a story of how the metonyms fit together if there are several of them etc. The reason something like this is needed is because the same thing can be interpreted in several ways; When [1 2 2 3] is seen as 123, it could be that the blemish exists in the second element, or in the last butone, or in the "2". The story indicates which of these is currently believed.
#
#    The story involves the metonymy_mode: this is an enum that can have the values NONE, ONE, ALLBUTONE and ALL, indicating "where" the blemish is. If it is the latter 2, all the metonyms must have the same category and meto_name. In general this may not be true: this is just a simplification I make to make the code managable.
#
# If the mode is ONE or ALLBUTONE, then another mode, position_mode, is important: whether positions are being considered absolute, or reverse absolute, or named.
#
# Finally, the position is also remebered.

#####################################################

package SBindings;
use strict;
use Carp;
use English qw( -no_match_vars );
use Class::Std;
use Class::Multimethods;
use Smart::Comments;

# variable: %bindings_of_of
#    The actual bindings like start => 1
my %bindings_of_of : ATTR(:get<bindings_ref>);

# variable: %squinting_raw_of
#    Hash ref: indexed by absolute positions in the object, and having values that are SMetonyms
my %squinting_raw_of : ATTR(:get<squinting_raw>);
my %metonymy_mode_of : ATTR(:get<metonymy_mode>);
my %position_mode_of : ATTR(:get<position_mode>);

# variable: %position_of
#    If positions are an issue, then this stores the current story of what the position is.
my %position_of : ATTR(:get<position>);

# variable: %metonymy_type_of
#    What is the metonymy type?
#
#    This includes the cat, name and info lost
my %metonymy_type_of : ATTR(:get<metonymy_type>);

#
# subsection: Creation

# method: create
# Creates an SBindings object
#
#    Arguments:
#    Slippages_ref - an array ref, each of whose elements is a Metonym
#    bindings_ref - a hash ref
#    object - needed to weave a story

sub create {
  my ( $package, $slippage_ref, $bindings_ref, $object ) = @_;
  ## SBindings constructor: $slippage_ref, $bindings_ref, $object
  ( defined($slippage_ref) and defined($bindings_ref) and defined($object) )
  or confess "Need three args!";
  return $package->new(
    {
      raw_slippages => $slippage_ref,
      bindings      => $bindings_ref,
      object        => $object,
    }
  );
}

# method: BUILD
# Builds the object
#
#    Sets bindings, squinting_raw. Then calls weave story that can set the other parameters.

sub BUILD {
  my ( $self, $id, $opts_ref ) = @_;
  $bindings_of_of{$id} = $opts_ref->{bindings} || confess "Need bindings";
  $squinting_raw_of{$id} = $opts_ref->{raw_slippages}
  || confess "Need slippages";
  my $object = $opts_ref->{object}
  || confess "Need object (in order to weave a story)";
  $self->_weave_story($object) unless $object->isa('SInt');
}

#
# subsection: Public Interface

# method: GetBindingForAttribute
# Extracts the particular value from the binding.
#
#    Example:
#    $bdg->GetBindingForAttribute("start")

sub GetBindingForAttribute {
  my ( $self, $what ) = @_;
  my $id = ident $self;

  return $bindings_of_of{$id}{$what};
}

# method: get_metonymy_cat
# Get the category slippage is based on.
#

sub get_metonymy_cat {
  my ($self) = @_;
  my $id = ident $self;

  return $metonymy_type_of{$id}->get_category();
}

# method: get_metonymy_name
# get the name of the slippage
#

sub get_metonymy_name {
  my ($self) = @_;
  my $id = ident $self;

  return $metonymy_type_of{$id}->get_name();
}

sub TellDirectedStory {
  my ( $self, $object, $position_mode ) = @_;
  my $id = ident $self;

  my $metonymy_mode = $self->get_metonymy_mode;
  return unless $metonymy_mode->is_position_relevant();

  if ( $metonymy_mode eq METO_MODE::ALLBUTONE() ) {
    confess "story retelling not implemented for this metonymy_mode";
  }
  my ($index) = keys %{ $squinting_raw_of{$id} };
  $self->_describe_position( $object, $index, $position_mode );
}

# method: tell_forward_story
# Reinterprets bindings so that now positions go in a forward direction.
#
# Assumption is that a story has already been woven once

sub tell_forward_story {
  my ( $self, $object ) = @_;
  $self->TellDirectedStory( $object, $POS_MODE::FORWARD );
}

# method: tell_backward_story
# Reinterprets bindings so that now positions go in a backward direction.
#
# Assumption is that a story has already been woven once

sub tell_backward_story {
  my ( $self, $object ) = @_;
  $self->TellDirectedStory( $object, $POS_MODE::BACKWARD );
}

#
# subsection: Private methods

# method: _weave_story
#  Given the raw arguments, this methods weaves a story: choosing a metonymy mode, position mode and so forth.
#
#    I should detail this function a lot more.

sub _weave_story {
  my ( $self, $object ) = @_;
  my $id = ident $self;

  my $slippages       = $squinting_raw_of{$id};
  my $object_size     = $object->get_parts_count();
  my $slippages_count = scalar( keys %$slippages );

  my ( $metonymy_mode, $position_mode, $position );
  my ( $metonymy_cat, $metonymy_name );
  my ($metonymy_type);

  # Metonymy_Mode
  if ( $slippages_count == 0 ) {
    $metonymy_mode = METO_MODE::NONE();
  }
  else {

    # So: slippages are involved!
    $metonymy_type = SMetonym->intersection( values %$slippages );

    if ( $slippages_count == $object_size ) {

      # XXX:If both are 1, I should have the choice of putting mode = 1!
      $metonymy_mode = METO_MODE::ALL();
    }
    elsif ( $slippages_count == 1 ) {
      $metonymy_mode = METO_MODE::SINGLE();
      $self->_describe_position( $object, keys %$slippages );
    }
  }

  $metonymy_mode_of{$id} = $metonymy_mode;

  #$position_mode_of{$id} = $position_mode;
  #$position_of{$id}      = $position;
  $metonymy_type_of{$id} = $metonymy_type;
}

# method: _describe_position
# Given the object and the (0 based) position index, returns a position mode and position.
#

sub _describe_position {
  my ( $self, $object, $index, $position_mode ) = @_;
  my $id = ident $self;

  $position_mode = POS_MODE::FORWARD();      # The only allowed now.
  $position_mode_of{$id} = $position_mode;
  return $position_of{$id} =
  SPos->new( $index + 1 );                   # It is 1-based, input is 0-based
}

1;

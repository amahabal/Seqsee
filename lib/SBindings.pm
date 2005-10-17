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
my %bindings_of_of :ATTR;

# variable: %squinting_raw_of
#    Hash ref: indexed by absolute positions in the object, and having values that are SMetonyms
my %squinting_raw_of :ATTR;

# variable: %metonymy_mode_of
#    How many metonymys are there?
#
#     * NONE
#     * ONE
#     * ALLBUTONE
#     * ALL
#
#    Stored in reality, currently, as 0, 1, 2 and 3.
my %metonymy_mode_of :ATTR;


# variable: %position_mode_of
#    If positions are an issue, how are positions reckoned? Can have one of the following values
#    * FORWARD
#    * BACKWARD
#    * NAMED
#     
my %position_mode_of :ATTR;


# variable: %position_of
#    If positions are an issue, then this stores the current story of what the position is.
my %position_of :ATTR;


# variable: %metonymy_cat_of
#    The category that allows this metonymy. Same as the cat of each metonymy in %squinting_raw_of
my %metonymy_cat_of :ATTR;


# variable: %metonymy_name_of
#    The name of the metonymy. Same as the name of each metonymy in %squinting_raw_of.
my %metonymy_name_of :ATTR;

#
# subsection: Creation



# method: create
# Creates an SBindings object
#
#    Arguments:
#    Slippages_ref - an array ref, each of whose elements is a Metonym
#    bindings_ref - a hash ref
#    object - needed to weave a story

sub create{
    my ($package, $slippage_ref, $bindings_ref, $object) = @_;
    ## SBindings constructor: $slippage_ref, $bindings_ref, $object
    return $package->new({ raw_slippages => $slippage_ref,
                           bindings      => $bindings_ref,
                           object        => $object,
                       });
}



# method: BUILD
# Builds the object
#
#    Sets bindings, squinting_raw. Then calls weave story that can set the other parameters.

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $bindings_of_of{$id} = $opts_ref->{bindings}       || die "Need bindings";
    $squinting_raw_of{$id} = $opts_ref->{raw_slippages}|| die "Need slippages";
    my $object = $opts_ref->{object} 
        || confess "Need object (in order to weave a story)";
    $self->_weave_story( $object );
}

#
# subsection: Public Interface



# method: get_binding
# Extracts the particular value from the binding.
#
#    Example:
#    $bdg->get_binding("start")

sub get_binding{
    my ( $self, $what ) = @_;
    my $id = ident $self;

    return $bindings_of_of{$id}{$what};
}


#
# subsection: Private methods



# method: _weave_story
#  Given the raw arguments, this methods weaves a story: choosing a metonymy mode, position mode and so forth.
#
#    I should detail this function a lot more.

sub _weave_story{
    my ( $self, $object ) = @_;
    my $id = ident $self;

    my $slippages = $squinting_raw_of{$id};
    my $object_size = $object->get_parts_count();
    my $slippages_count = scalar(keys %$slippages);

    my ($metonymy_mode, $position_mode, $position); 
    my ($metonymy_cat, $metonymy_name); 

    # Metonymy_Mode
    if ($slippages_count == 0) {
        $metonymy_mode = 0;
    } elsif ($slippages_count == $object_size) {
        # XXX:If both are 1, I should have the choice of putting mode = 1!
        $metonymy_mode = 3;
        my $metonym_type = SMetonym->intersection(values %$slippages);
        $metonymy_cat  = $metonym_type->get_category;
        $metonymy_name = $metonym_type->get_name;
    } elsif ($slippages_count == 1) {
        $metonymy_mode = 1;
        my $metonym_type = (values %$slippages)[0]->get_type;
        ($metonymy_cat, $metonymy_name) = ($metonym_type->get_category,
                                           $metonym_type->get_name,
                                               );

        # Describe position. Slippage key is the index
        ($position_mode, $position) 
            = $self->_describe_position( $object, keys %$slippages );
    }

    $metonymy_mode_of{$id} = $metonymy_mode;
    $position_mode_of{$id} = $position_mode;
    $position_of{$id}      = $position;
    $metonymy_cat_of{$id}  = $metonymy_cat;
    $metonymy_name_of{$id} = $metonymy_name;
}




# method: _describe_position
# Given the object and the (0 based) position index, returns a position mode and position.
#

sub _describe_position{
    my ( $self, $object, $index ) = @_;

    # XXX: Will only be fwd or backward, currently
    my $position_mode = SUtil::toss(0.5) ? 1 : 2; #1 is FWD, 2 is BWD
    
    if ($position_mode == 1) {
        return SPos->new( $index + 1); # It is 1-based, input is 0-based
    } else {
        my $object_size = $object->get_parts_count;
        return SPos->new( $index - $object_size );
    }
}

1;

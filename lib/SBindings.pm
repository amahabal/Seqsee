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
        || die "Need object (in order to weave a story)";
    $self->_weave_story( $object );
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

    my $slippages = $raw_slippages{$id};
    my $object_size = $object->get_parts_count();
    my $slippages_count = scalar(@$slippages);

    my ($metonymy_mode, $position_mode, $position); 
    my ($metonymy_cat, $metonymy_name); 

    # Metonymy_Mode
    if ($slippages_count == 0) {
        $metonymy_mode = 0;
    } elsif ($slippages_count == $object_size) {
        # XXX:If both are 1, I should have the choice of putting mode = 1!
        $metonymy_mode = 3;
        my @metonym_types = map { $_->get_type() } @$slippages;
        my $metonym_type = SMetonymType->intersection(@metonym_types);
        $metonymy_cat  = $metonym_type->get_cat;
        $metonymy_name = $metonym_type->get_name;
    } elsif ($slippages_count == 1) {
        $metonymy_mode = 1;
        my $metonym_type = $slippages->[0]->get_type;
        ($metonymy_cat, $metonymy_name) = ($metonym_type->get_cat,
                                           $metonym_type->get_name,
                                               );
        ($position_mode, $position) = $self->_describe_position( $object );
    }
}




#
# subsection: Defunct Stuff

my %values_of_of : ATTR( :get<values_of> );
my %blemishes_of : ATTR( :get<blemishes> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $blemishes_of{$id} = [];
}



#### method add_blemish
# description    :marks the binding as being based on this blemish
# argument list  :$self: SBindings::Blemish $blemish
# return type    :none
# context of call:void
# exceptions     :none

sub add_blemish {
    my ( $self, $blemish ) = @_;
    UNIVERSAL::isa( $blemish, "SBindings::Blemish" )
        or croak "Need SBindings::Blemish";
    push( @{ $blemishes_of{ ident $self} }, $blemish );
}

sub set_value_of {
    my ( $self, $what_ref ) = @_;
    my $val_ref = ( $values_of_of{ ident $self} ||= {} );
    while ( my ( $k, $v ) = each %$what_ref ) {
        $val_ref->{$k} = $v;
    }
}

sub as_hash : HASHIFY {
    my ($self) = shift;
    return { %{ $values_of_of{ ident $self} } };
}

sub get_where {
    my ($self) = shift;
    return [ map { $_->get_where } @{ $blemishes_of{ ident $self} } ];
}

sub get_real {
    my ($self) = shift;
    return [ map { $_->get_real } @{ $blemishes_of{ ident $self} } ];
}

sub get_starred {
    my ($self) = shift;
    return [ map { $_->get_starred } @{ $blemishes_of{ ident $self} } ];
}

sub get_blemished {
    my ($self) = shift;
    return scalar @{ $blemishes_of{ ident $self} };
}

multimethod 'find_reln';

#### method _find_reln
# description    :finds relationship between two bindings. Intended to be private: does not return an SReln object, but just something that others may use.
# argument list  :SBlemish, SBlemish
# return type    :hashref: keys are the keys for the bindings, values are SRelns
# context of call:scalar
# exceptions     :??

multimethod _find_reln => qw(SBindings SBindings) => sub
    {
        my ($b1, $b2) = @_;
        my $ret_hash_ref;
        my @unrelated_attributes;
        my $v_hash_1 = $values_of_of{ident $b1};
        my $v_hash_2 = $values_of_of{ident $b2};
        while (my ($k, $v1) = each %$v_hash_1) {
            next unless exists $v_hash_2->{$k};
            my $v2 = $v_hash_2->{$k};
            my $reln;
            eval { $reln = find_reln($v1, $v2) };
            if ($EVAL_ERROR or not(defined $reln)) {
                push @unrelated_attributes, $k;
                print "\tthe bindings seem unrelated regarding $k\n";
                #XXX do something about this!
                next;
            }
            $ret_hash_ref->{$k} = $reln;
        }
        if (%$ret_hash_ref) {
            # aha. I have something to return!
            return $ret_hash_ref;
        } else {
            return;
        }
    };

multimethod build_right => qw(SBuiltObj HASH) =>
    sub {
        my ( $bindings, $reln_hash ) = @_;
        my $v_hash_1 = $values_of_of{ident $bindings};
        my $new_bindings_hash;
        #... should now apply relns to this, return the hash...
    };


1;

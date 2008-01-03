#####################################################
#
#    Package: SReln::Compound
#
#####################################################
#   Manages relations between objects that are more complex than just "successor".
#
#   The nature of relations is very stroingly coupled with the nature of SBindings.
# My current thoughts look like what follows.
#
#   Base Category:
#   A relation is based on both objects belonging to a category. For example, the relation between
# [1 2 3] and [1 2 3 4] is based on the category "ascending". Maybe this is a blunder on my part:
# While triangle and square are so related (by the category "Polygon"), Bloomington and Indiana do
# not share such a category directly. Maybe there is a large range of things in Seqsee domain of
# the Bloomington-Indiana type. When [2 2 2] is seen as a 2, it is an event of this type, perhaps.
# I am not calling that a relation, but rather a metonym, but maybe that too is a blunder. But Let
# me carry on with this figment for now.
#
#   Base Metonymy Mode:
#   If two objects are to have a relation, I'd like them to have the same metonymy mode: No
# blemish, a single blemish or everything blemished (or maybe even "everything upto a point
# blemished").
#
#   Base Position Mode:
#   They should also share the same way of looking at positions. See SBindings for details.
#
#   Changed Bindings:
#   A hashref of what bindings changed, and how. E.g., start => successor
#
#   Position:
#   Indicates what happened to the position. Could indicate a change or "same"
#
#####################################################

package SReln::Compound;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln SInstance };
use Smart::Comments;
use List::Util qw(sum shuffle);

multimethod 'find_relation_string';
multimethod 'find_relation_type';

my %type_of : ATTR(:get<type>);        # The SRelnType::Compound object.
my %first_of : ATTR( :get<first>, :set<first> );    # First object. Not necessarily the left.
my %second_of : ATTR( :get<second>, :set<second> );  # Second object.

sub get_pure           { return $type_of{ ident $_[0] } }
sub get_base_category  { return $type_of{ ident $_[0] }->get_base_category() }
sub get_base_meto_mode { return $type_of{ ident $_[0] }->get_base_meto_mode() }
sub get_base_pos_mode  { return $type_of{ ident $_[0] }->get_base_pos_mode() }
sub suggest_cat_for_ends { return $type_of{ ident $_[0]}->suggest_cat_for_ends() }


sub get_changed_bindings_ref {
    return $type_of{ ident $_[0] }->get_changed_bindings_ref();
}
sub get_position_reln  { return $type_of{ ident $_[0] }->get_position_reln() }
sub get_metonymy_reln  { return $type_of{ ident $_[0] }->get_metonymy_reln() }
sub get_direction_reln { return $type_of{ ident $_[0] }->get_direction_reln() }

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;

    my $first  = $first_of{$id}  = $opts_ref->{first};
    my $second = $second_of{$id} = $opts_ref->{second};
    confess unless $first->isa('SObject');
    confess unless $second->isa('SObject');

    $opts_ref->{dir_reln} =
      find_reln( $first->get_direction(), $second->get_direction() );
    $type_of{$id} = SRelnType::Compound->create($opts_ref);

    $self->AddHistory("Created");
}

#
# subsection: Finding relations

# multi: find_reln ( SObject, SObject )
# Finds a relation between the two objects
#
#    Finds a common category, and choosing one, calls the variant of the function with a third argument, the category
#
#    usage:
#     my $reln = find_reln($o1, $o2)
#
#    parameter list:
#        $o1 - object1
#        $o2 - object2
#
#    return value:
#      The relation
#
#    possible exceptions:
#        Don't know for sure how to do this, but I had planned for this to return exceptions seeking more information also.

# XXX: THIS IS A KLUDGE. _find_reln should be renamed _find_relntype, and changed appropriately...
multimethod _find_reln => qw(SObject SObject) => sub {
    my ( $o1, $o2 ) = @_;
    my @common_categories = $o1->get_common_categories($o2);
    ## @common_categories
    return unless @common_categories;

# XXX(Board-it-up): [2006/11/07] change: SLTM::ChooseConceptGivenConcept(\@common_categories)
    my $cat = $common_categories[0];

    ## $cat

    return $cat->FindRelationBetween($o1, $o2);
    # return _find_reln( $o1, $o2, $cat );
};

multimethod find_relation_string => ('#', 'SElement') => sub {
    my ( $num, $elt ) = @_;
    return find_relation_string($num, $elt->get_mag());
};

multimethod find_relation_string => ('SElement', '#') => sub {
    my ( $elt, $num ) = @_;
    return find_relation_string($elt->get_mag(), $num);
};


# method: find_reln
# calls _find_reln
#
multimethod find_reln => qw(SObject SObject SCat::OfObj) => sub {
    my ( $original_o1, $original_o2, $cat ) = @_;
    my $o1 = $original_o1->GetEffectiveObject;
    my $o2 = $original_o2->GetEffectiveObject;
    my $ret = $cat->FindRelationBetween( $o1, $o2 ) or return;
    $ret->set_first($original_o1);
    $ret->set_second($original_o2);
    return $ret;
};

multimethod find_reln => qw(SObject SObject) => sub {
    my ( $original_o1, $original_o2, $cat ) = @_;
    my $o1 = $original_o1->GetEffectiveObject;
    my $o2 = $original_o2->GetEffectiveObject;
    my $ret = _find_reln( $o1, $o2 ) or return;
    $ret->set_first($original_o1);
    $ret->set_second($original_o2);
    return $ret;
};

multimethod apply_reln => qw(SReln::Compound SObject) => sub {
    my ( $reln, $object ) = @_;

    return apply_reln( $reln->get_type(), $object );
};

multimethod are_relns_compatible => qw(SReln SReln) => sub {
    return;    #we are here if one is simple, the other compound.
};

multimethod are_relns_compatible => qw(SReln::Compound SReln::Compound) => sub {
    my ( $a, $b ) = @_;
    return $a->get_type() eq $b->get_type();
};

multimethod are_relns_compatible => qw($ $) => sub {
    my ( $a, $b ) = @_;
    confess "are_relns_compatible called with '$a' and '$b'!";
};

sub as_text {
    my ($self) = @_;
    my $id = ident $self;

    my ($first, $second) = map { SUtil::StringifyForCarp($_) } ($first_of{$id}, $second_of{$id});
    my $rest;
    if ($Global::Feature{debug}) {
        $rest = SUtil::StringifyForCarp($type_of{$id});
    }
    return "SReln::Compound($first ---> $second) <$rest>";
}

#sub suggest_cat {
#    my ($self) = @_;#
#
#}

sub UpdateStrength {
    my ($self) = @_;
    my $type = $self->get_type;
    my $strength = 100 * SLTM::GetRealActivationsForOneConcept($type);
    my $complexity_penalty = $type->get_complexity_penalty;
    $strength *= $complexity_penalty;

    # Holeyness penalty
    $strength *= 0.8 if $self->get_holeyness;

    $strength = 100 if $strength > 100;
    $self->set_strength($strength);
}

sub FlippedVersion {
    my ($self) = @_;
    my $base_category = $self->get_type()->get_base_category();
    return find_reln( reverse( $self->get_ends() ), $base_category );
}

1;

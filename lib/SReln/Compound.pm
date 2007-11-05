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
use List::MoreUtils qw(uniq);

multimethod 'find_relation_string';
multimethod 'find_relation_type';

my %type_of : ATTR(:get<type>);        # The SRelnType::Compound object.
my %first_of : ATTR( :get<first> );    # First object. Not necessarily the left.
my %second_of : ATTR( :get<second> );  # Second object.

sub get_pure           { return $type_of{ ident $_[0] } }
sub get_base_category  { return $type_of{ ident $_[0] }->get_base_category() }
sub get_base_meto_mode { return $type_of{ ident $_[0] }->get_base_meto_mode() }
sub get_base_pos_mode  { return $type_of{ ident $_[0] }->get_base_pos_mode() }

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

multimethod _find_reln => qw(SObject SObject) => sub {
    my ( $o1, $o2 ) = @_;
    my @common_categories = $o1->get_common_categories($o2);
    ## @common_categories
    return unless @common_categories;

# XXX(Board-it-up): [2006/11/07] change: SLTM::ChooseConceptGivenConcept(\@common_categories)
    my $cat = $common_categories[0];

    ## $cat

    return _find_reln( $o1, $o2, $cat );
};

multimethod find_relation_string => ('#', 'SElement') => sub {
    my ( $num, $elt ) = @_;
    return find_relation_string($num, $elt->get_mag());
};

multimethod find_relation_string => ('SElement', '#') => sub {
    my ( $elt, $num ) = @_;
    return find_relation_string($elt->get_mag(), $num);
};


# multi: find_reln ( SObject, SObject, SCat::OfObj::Std )

multimethod _find_reln => qw(SObject SObject SCat::OfObj) => sub {
    my ( $o1, $o2, $cat ) = @_;

    ## In_find_reln: $o1, $o2, $cat
    my $opts_ref = {};

    $opts_ref->{first}  = $o1;
    $opts_ref->{second} = $o2;

    # Base category
    my $b1 = $o1->is_of_category_p($cat) or return;

    my $b2 = $o2->is_of_category_p($cat) or return;

    $opts_ref->{base_category} = $cat;

    ## Base Category found: $cat

    # Meto mode
    my $meto_mode = $b1->get_metonymy_mode;
    return unless $meto_mode eq $b2->get_metonymy_mode;
    $opts_ref->{base_meto_mode} = $meto_mode;

    ## Base meto mode found: $meto_mode

    CalculateBindingsChange( $opts_ref, $b1->get_bindings_ref(),
        $b2->get_bindings_ref(), $cat )
      or return;

    ## bindings: %bindings_1, %bindings_2
    ## changed_bindings found: $changed_ref
    ## unchanged_bindings found: $unchanged_ref

    if ( $meto_mode->is_metonymy_present() ) {

        # So other stuff is relevant, too!
        if ( $meto_mode->is_position_relevant() ) {    # Position relevant!
            my $pos_mode = $b1->get_position_mode;
            ## $b2->get_position_mode
            return unless $pos_mode == $b2->get_position_mode;
            $opts_ref->{base_pos_mode} = $pos_mode;
            ## position_mode_found: $pos_mode

            my $rel = find_reln( $b1->get_position(), $b2->get_position() );
            return unless $rel;
            $opts_ref->{position_reln} = $rel;

            my $meto_type_1 = $b1->get_metonymy_type;
            my $meto_type_2 = $b2->get_metonymy_type;
            $rel = find_reln( $meto_type_1, $meto_type_2 );
            return unless $rel;
            $opts_ref->{metonymy_reln} = $rel;

            ## Starred relation, unstarred reln, metonymy_reln?
            ## Need to work that out
        }
    }

    return SReln::Compound->new($opts_ref);
};

sub CalculateBindingsChange {

    # my ( $output_ref, $bindings_1, $bindings_2, $cat ) = @_;
    ##CalculateBindingsChange:

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
              "In _find_reln($$$): binding for $k missing for second object!";
        }
        my $v2 = $bindings_2->{$k};
        if ( $v1 eq $v2 ) {
            $unchanged_ref->{$k} = $v1;
            next;
        }
        my $rel = find_relation_type( $v1, $v2 );
        ## k, v1, v2, rel: $k, $v1, $v2, $rel
        return unless $rel;
        $changed_ref->{$k} = $rel;
    }
    $output_ref->{changed_bindings}   = $changed_ref;
    $output_ref->{unchanged_bindings} = $unchanged_ref;
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
            if ( $v eq $v2 ) {
                $unchanged_ref->{$k2} = $v2;
                $slips_ref->{$k2}     = $k;
                ## v = v2:
                next LOOP;
            }
            my $rel = find_relation_type( $v, $v2 );
            next unless $rel;
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
        return unless CalculateBindingsChange_with_slips({},# don't care
                                                         $bindings_2,
                                                         $bindings_1,
                                                         $cat,
                                                         1 # is_reverse true
                                                             );
        ## reverse ok :
        #print "H";
    }
    $output_ref->{slippages} = $slips_ref;
    return 1;
}

# method: find_reln
# calls _find_reln
#
multimethod find_reln => qw(SObject SObject SCat::OfObj) => sub {
    my ( $o1, $o2, $cat ) = @_;
    $o1 = $o1->GetEffectiveObject;
    $o2 = $o2->GetEffectiveObject;
    my $ret = _find_reln( $o1, $o2, $cat );
    return $ret;
};

multimethod find_reln => qw(SObject SObject) => sub {
    my ( $o1, $o2 ) = @_;
    $o1 = $o1->GetEffectiveObject();
    $o2 = $o2->GetEffectiveObject();
    _find_reln( $o1, $o2 );
};

multimethod apply_reln => qw(SReln::Compound SObject) => sub {
    my ( $reln, $object ) = @_;

    return apply_reln( $reln->get_type(), $object );
};

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    if ( $verbosity == 0 ) {
        return new SInsertList( "SReln::Compound", "heading", "\n" );
    }

    if ( $verbosity == 1 ) {
        my $list = $self->as_insertlist(0);
        $list->append( "first: ", "first_second", "\n" );
        $list->concat( $first_of{$id}->as_insertlist(0)->indent(1) );

        $list->append( "Second: ", "first_second", "\n" );
        $list->concat( $second_of{$id}->as_insertlist(0)->indent(1) );
        $list->append("\n");
        return $list;
    }

    if ( $verbosity == 2 ) {
        my $list = $self->as_insertlist(0);
        $list->append( "Type: ", "first_second", "\n" );
        $list->concat( $type_of{$id}->as_insertlist(1)->indent(1) );
        $list->append( "History: ", 'heading', "\n" );
        for ( @{ $self->get_history } ) {
            $list->append("$_\n");
        }
        return $list;
    }

    confess "Verbosity $verbosity not implemented for " . ref $self;
}

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
    return "SReln::Compound";
}

# XXX(Board-it-up): [2007/02/03] should the next two methods be removed?
sub suggest_cat {
    my ($self) = @_;
    return;
}

sub suggest_cat_for_ends {
    my ($self) = @_;
    return $type_of{ ident $self}->suggest_cat_for_ends();
}

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

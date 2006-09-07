#####################################################
#
#    Package: SReln::Compound
#
#####################################################
#   Manages relations between objects.
#    
#   The nature of relations is very stroingly coupled with the nature of SBindings. My current thoughts look like what follows.
#    
#   Base Category:
#   A relation is based on both objects belonging to a category. For example, the relation between [1 2 3] and [1 2 3 4] is based on the category "ascending". Maybe this is a blunder on my part: While triangle and square are so related (by the category "Polygon"), Bloomington and Indiana do not share such a category directly. Maybe there is a large range of things in Seqsee domain of the Bloomington-Indiana type. When [2 2 2] is seen as a 2, it is an event of this type, perhaps. I am not calling that a relation, but rather a metonym, but maybe that too is a blunder. But Let me carry on with this figment for now.
#    
#   Base Metonymy Mode:
#   If two objects are to have a relation, I'd like them to have the same metonymy mode: No blemish, a single blemish or everything blemished.
#    
#   Base Position Mode:
#   They should also share the same way of looking at positions. See SBindings for details.
#    
#   Unchanged Bindings:
#   A hashref of what bindings stayed put. Keys are binding keys, values are binding values (e.g., length => 3)
#    
#   Changed Bindings:
#   A hashref of what bindings changed, and how. E.g., start => successor
#    
#   Position:
#   Indicates what happened to the position. Could indicate a change or "same"
#    
#   Unstarred Relation:
#   If there is a single metonymy involved, this indicates the relation between the unstarred versions.
#    
#   Starred Relation:
#   as above. But what happens when the metonymy_mode is "ALL" I do not yet know.
#####################################################

package SReln::Compound;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln SInstance };
use Smart::Comments;

multimethod 'apply_reln_direction';

# variable: %base_category_of
#    Category on which this relation is based
my %base_category_of :ATTR(:get<base_category>);

# variable: %base_meto_mode_of
#    The meto_mode common to both objects
my %base_meto_mode_of :ATTR(:get<base_meto_mode>);

# variable: %base_pos_mode_of
#    The common position mode
my %base_pos_mode_of :ATTR(:get<base_pos_mode>);

# variable: %unchanged_bindings_of_of
#    What binding have not changed?
#     
#    Keys are attributes, values are the common values they have
my %unchanged_bindings_of_of :ATTR(:get<unchanged_bindings_ref>);

# variable: %changed_bindings_of_of
#    What bindings have changed?
#
#    Keys are attributes, values are relations.
my %changed_bindings_of_of :ATTR(:get<changed_bindings_ref>);

# variable: %position_reln_of
#    How has the position changed?
my %position_reln_of :ATTR(:get<position_reln>);


# variable: #%unstarred_reln_of
#    Relation between the unstarred parts of the metonyms if metonyms involved
#my %unstarred_reln_of :ATTR(:get<unstarred_reln>);

# variable: #%starred_reln_of
#    Same as above, starred
#my %starred_reln_of :ATTR( :get<starred_reln>);


# variable: %metonymy_reln_of
#    What is the relationship between the metonymys?
my %metonymy_reln_of :ATTR( :get<metonymy_reln>);

# variable: #%lost_categories_of
#    What categories are lost? I may want to add this later.

# variable: #%gained_categories_of
#    What categories are gained? I may want to add this later.

# variable: %first_of
#    Ref to the first of the two objects. 
#     
#    Does not necessarily mean the left object.
my %first_of : ATTR( :get<first> );


# variable: %second_of
#    Ref to the second
my %second_of : ATTR( :get<second> );



# method: BUILD
# Builds the object.
#
#     Needs the following:
#    * base_category
#    * base_meto_mode
#    * base_pos_mode
#    * unchanged_bindings
#    * changed_bindings
#    * position_reln
#    * # unstarred_reln #may not need this
#    * # starred_reln  #may not need this
#    * metonymy_reln

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;

    $first_of{$id} = $opts_ref->{first};
    $second_of{$id}= $opts_ref->{second};

    $base_category_of{$id} = $opts_ref->{base_category}
        or confess "Need base category";

    my $meto_mode = $base_meto_mode_of{$id} = $opts_ref->{base_meto_mode};
    confess "Need base meto mode" unless defined $meto_mode;

    $changed_bindings_of_of{$id} = $opts_ref->{changed_bindings}
        or confess "Need changed bindings";
    $unchanged_bindings_of_of{$id} = $opts_ref->{unchanged_bindings}
        or confess "Need unchanged_bindings";
    
    if ($meto_mode) { # that is, metonymy's present!
        my $pos_mode = $base_pos_mode_of{$id} = $opts_ref->{base_pos_mode};
        confess "Need base pos mode" unless defined($pos_mode);

        #$unstarred_reln_of{$id} = $opts_ref->{unstarred_reln}
        #    or confess "Need unstarred relation";
        #$starred_reln_of{$id} = $opts_ref->{starred_reln}
        #    or confess "Need starred relation";
        $metonymy_reln_of{$id} = $opts_ref->{metonymy_reln};

        if ($meto_mode != METO_MODE::ALL()) { # So: some, but not all, starred
            $position_reln_of{$id} = $opts_ref->{position_reln}
                or confess "Need position reln";
        }

    }
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

    # Without the choosing infra, I'll just choose the first
    my $cat = $common_categories[0];

    ## $cat

    return find_reln($o1, $o2, $cat);
};



# multi: find_reln ( SObject, SObject, SCat::OfObj )
# find relation based on the category
#
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:

multimethod _find_reln => qw(SObject SObject SCat::OfObj) => sub {
    my ( $o1, $o2, $cat ) = @_;

    ## In_find_reln: $o1, $o2, $cat
    my $opts_ref = {};

    $opts_ref->{first}  = $o1;
    $opts_ref->{second} = $o2;
    
    # Base category
    my $b1 = $o1->is_of_category_p($cat);
    return unless $b1->[0];
    $b1 = $b1->[1];

    my $b2 = $o2->is_of_category_p($cat);
    return unless $b2->[0];
    $b2 = $b2->[1];

    $opts_ref->{base_category} = $cat;

    ## Base Category found: $cat

    # Meto mode
    my $meto_mode = $b1->get_metonymy_mode;
    return unless $meto_mode == $b2->get_metonymy_mode;
    $opts_ref->{base_meto_mode} = $meto_mode;

    ## Base meto mode found: $meto_mode


    #bindings
    my $changed_ref = {};
    my $unchanged_ref = {};
    my $bindings_1 = $b1->get_bindings_ref;
    my $bindings_2 = $b2->get_bindings_ref;
    while (my ($k, $v1) = each %$bindings_1) {
        next unless exists $bindings_2->{$k};
        my $v2 = $bindings_2->{$k};
        if ($v1 eq $v2) {
            $unchanged_ref->{$k} = $v1;
            next;
        }
        ## $k, $v1
        my $rel = find_reln($v1, $v2);
        return unless $rel;
        $changed_ref->{$k} = $rel;
    }
    $opts_ref->{changed_bindings} = $changed_ref;
    $opts_ref->{unchanged_bindings} = $unchanged_ref;

    ## changed_bindings found: $changed_ref
    ## unchanged_bindings found: $unchanged_ref

    if ($meto_mode) {
        # So other stuff is relevant, too!
        if ($meto_mode != METO_MODE::ALL()) { # Position relevant!
            my $pos_mode = $b1->get_position_mode;
            ## $b2->get_position_mode
            return unless $pos_mode == $b2->get_position_mode;
            $opts_ref->{base_pos_mode} = $pos_mode;
            ## position_mode_found: $pos_mode

            my $rel = find_reln($b1->get_position(),
                                $b2->get_position()
                                    );
            return unless $rel;
            $opts_ref->{position_reln} = $rel;

            my $meto_type_1 = $b1->get_metonymy_type;
            my $meto_type_2 = $b2->get_metonymy_type;
            $rel = find_reln($meto_type_1,
                             $meto_type_2
                                 );
            return unless $rel;
            $opts_ref->{metonymy_reln} = $rel;

            ## Starred relation, unstarred reln, metonymy_reln?
            ## Need to work that out
        }
    }

    return SReln::Compound->new($opts_ref);
};



# method: find_reln
# calls _find_reln
#
multimethod find_reln => qw(SObject SObject SCat::OfObj) => sub {
    my ($o1, $o2, $cat) = @_;
    $o1 = $o1->get_effective_object;
    $o2 = $o2->get_effective_object;
    my $ret = _find_reln($o1, $o2, $cat);
    return $ret;
};
multimethod find_reln => qw(SObject SObject) => sub {
    my ($o1, $o2) = @_;
    $o1 = $o1->get_effective_object;
    $o2 = $o2->get_effective_object;
    _find_reln($o1, $o2);
};

# 
# subsection: Defunct Stuff




# method: get_both
# Returns both the objects

sub get_both{
    my $self = shift;
    my $ident = ident $self;
    return ( $first_of{$ident}, $second_of{$ident} );
}



# multi: apply_reln ( SReln::Compound, SObject )
# Apply relan to object
#
#    Perhaps the most complex of the apply_reln family, 
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:

multimethod apply_reln => qw(SReln::Compound SObject) => sub {
    my ( $reln, $object ) = @_;
    
    # Find category for new object
    my $cat = $reln->get_base_category;

    # Make sure the object belongs to that category
    my $bindings = $object->describe_as( $cat );
    ## $bindings
    ## $cat->as_text
    return unless $bindings;


    # Find the bindings for it.
    my $bindings_ref = $bindings->get_bindings_ref;
    my $changed_bindings_ref = $reln->get_changed_bindings_ref;
    my $new_bindings_ref = {};

    while (my($k, $v) = each %$bindings_ref) {
        if (exists $changed_bindings_ref->{$k}) {
            $new_bindings_ref->{$k} = apply_reln( $changed_bindings_ref->{$k},
                                                  $v
                                                      );
            next;
        }
        # no change...
        $new_bindings_ref->{$k} = $v;
    }
    my $ret_obj = $cat->build( $new_bindings_ref );
    ## $new_bindings_ref
    # We have not "applied the blemishes" yet, of course

    my $reln_meto_mode = $reln->get_base_meto_mode;
    my $object_meto_mode = $bindings->get_metonymy_mode;
    unless ($reln_meto_mode == $object_meto_mode) {
        ## reln_meto_mode isnot object_meto_mode
        return;
    }
    
    unless($reln_meto_mode == METO_MODE::NONE()){
        # Calculate the metonymy type of the new object
        my $new_metonymy_type = apply_reln( $reln->get_metonymy_reln,
                                            $bindings->get_metonymy_type
                                                );
        return unless $new_metonymy_type;

        if ($reln_meto_mode == 3) {
            $ret_obj = $ret_obj->apply_blemish_everywhere( $new_metonymy_type )
        } else {
            # If we get here, position is relevant!
            my $new_position = apply_reln( $reln->get_position_reln,
                                           $bindings->get_position
                                               );
            return unless $new_position;
            ## $reln->get_position_reln()->get_text()
            ## $bindings->get_position()->get_index
            ## $new_position->get_index()
            ## $reln_meto_mode
        
            ## $bindings->get_metonymy_type()->get_info_loss()
            ## $reln->get_metonymy_reln()->get_change_ref()
            ## $new_metonymy_type->get_info_loss() 
            
            ## $new_object->get_structure
            $ret_obj =
                $ret_obj->apply_blemish_at( $new_metonymy_type, $new_position );
            ## new object: $ret_obj->get_structure
        }
    }
     
    $ret_obj->describe_as($cat);

    my $rel_dir = $reln->get_direction_reln;
    my $obj_dir = $object->get_direction;
    my $new_dir = apply_reln_direction( $rel_dir, $obj_dir);

    $ret_obj->set_direction( $new_dir );
    return $ret_obj;

};

sub as_insertlist{
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    if ($verbosity == 0) {
        return new SInsertList( "SReln::Compound", "heading", "\n" );
    }

    if ($verbosity == 1) {
        my $list = $self->as_insertlist(0);
        $list->append("first: ", "first_second", "\n");
        $list->concat( $first_of{$id}->as_insertlist(0)->indent(1) );

        $list->append("Second: ", "first_second", "\n");
        $list->concat( $second_of{$id}->as_insertlist(0)->indent(1) );
        $list->append("\n");
        return $list;
    }

    if ($verbosity == 2) {
        my $list = $self->as_insertlist(0);
        $list->append("first: ", "first_second", "\n");
        $list->concat( $first_of{$id}->as_insertlist(1)->indent(1) );

        $list->append("Second: ", "first_second", "\n");
        $list->concat( $second_of{$id}->as_insertlist(1)->indent(1) );
        $list->append("\n");

        $list->append( "Base Category: ", "heading2", "\n");
        $list->concat( $base_category_of{$id}->as_insertlist(1)->indent(1));

        $list->append( "Base Meto mode: ", "heading2", "\n");
        $list->concat( SInsertList->new($base_meto_mode_of{$id})->indent(1));
        $list->append("\n");

        $list->append( "Base Pos Mode: ", "heading2", "\n");
        $list->concat( SInsertList->new($base_pos_mode_of{$id})->indent(1));
        $list->append("\n");

        $list->append( "Changed Bindings: ", "heading2", "\n");
        while (my($k, $v) = each %{$changed_bindings_of_of{$id}}) {
            my $sublist = new SInsertList;
            $sublist->append($k, "", "\t", "");
            $sublist->concat($v->as_insertlist(0)->indent(1));
            $list->concat( $sublist->indent(1) );
        }

        $list->append( "Unchanged Bindings: ", "heading2", "\n");
        while (my($k, $v) = each %{$unchanged_bindings_of_of{$id}}) {
            $list->concat( SInsertList->new($k, "", "\t", "", $v, "\n")->indent(1));
        }

        $list->append( "History: ", 'heading', "\n");
        for (@{$self->get_history}) {
            $list->append("$_\n");
        }


        return $list;
    }

    confess "Verbosity $verbosity not implemented for ". ref $self;
}

multimethod are_relns_compatible => qw(SReln::Compound SReln::Compound) => sub{
    my ($a, $b) = @_;
    $a->get_base_category eq $b->get_base_category or return;
    
    my $a_cbr = $a->get_changed_bindings_ref;
    my $b_cbr = $b->get_changed_bindings_ref;
    scalar(keys %$a_cbr) == scalar(keys %$b_cbr) or return;

    while (my($k, $v) = each %$a_cbr) {
        my $v2 = $b_cbr->{$k};
        unless ($v2 and are_relns_compatible($v, $v2)) {
            return;
        }
    }

    if ($a->get_base_meto_mode() == $METO_MODE::NONE and
            $b->get_base_meto_mode() == $METO_MODE::NONE
                ) {
        return 1;
    }

    are_relns_compatible($a->get_position_reln(), $b->get_position_reln())
        or return;
    are_relns_compatible($a->get_metonymy_reln(), $b->get_metonymy_reln())
        or return;

    return 1;

};

multimethod are_relns_compatible => qw($ $) => sub {
    my ( $a, $b ) = @_;
    die "are_relns_compatible called with '$a' and '$b'!";
};

sub as_text{
    my ( $self ) = @_;
    return "SReln::Compound";
}

sub suggest_cat{
    my ( $self ) = @_;
    return;
}


1;

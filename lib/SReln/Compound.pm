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

        if ($meto_mode != 3) { # So: some, but not all, starred
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

multimethod find_reln => qw(SObject SObject) => sub {
    my ( $o1, $o2 ) = @_;
    my @common_categories = $o1->get_common_categories($o2);
    return unless @common_categories;

    # Without the choosing infra, I'll just choose the first
    my $cat = $common_categories[0];

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

multimethod find_reln => qw(SObject SObject SCat::OfObj) => sub {
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
        if ($meto_mode != 3) { # Position relevant!
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
    my $bindings = $object->get_binding( $cat );
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
    my $new_object = $cat->build( $new_bindings_ref );
    
    # We have not "applied the blemishes" yet, of course

    my $reln_meto_mode = $reln->get_base_meto_mode;
    my $object_meto_mode = $bindings->get_metonymy_mode;
    unless ($reln_meto_mode == $object_meto_mode) {
        return;
    }
    
    return $new_object if $reln_meto_mode == 0;

    # Calculate the metonymy type of the new object
    my $new_metonymy_type = apply_reln( $reln->get_metonymy_reln,
                                        $bindings->get_metonymy_type
                                            );
    return unless $new_metonymy_type;

    if ($reln_meto_mode == 3) {
        return $new_object->apply_blemish_everywhere( $new_metonymy_type )
    } 

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
    return $new_object->apply_blemish_at( $new_metonymy_type, $new_position );

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

        return $list;
    }

    die "Verbosity $verbosity not implemented for ". ref $self;
}


1;

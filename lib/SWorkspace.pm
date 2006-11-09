#####################################################
#
#    Package: SWorkspace
#
#####################################################
#   manages the workspace
#####################################################

package SWorkspace;
use strict;
use warnings;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};

use Perl6::Form;
use Smart::Comments;

use Sort::Key qw{rikeysort};

# Next 2 lines: should be my!
our $elements_count;
our @elements = ();

# variable: %groups
#    All groups
our %groups;

# variable: $ReadHead
#    Points just beyond the last object read.
#
#    If never called before any reads, points to 0.
our $ReadHead = 0;

# variable: %relations
our %relations;

#XXX needs to be filled
our %POLICY = (
    gp_add => sub {
        my ($gp) = @_;
        1;
    },
    gp_rem => sub {
        my ($gp) = @_;
        1;
    },
    rel_add => sub {
        my ($rel) = @_;
        1;
    },
    rel_rem => => sub {
        my ($rel) = @_;
        1;
    },

);

# method: clear
#  starts workspace off as new

sub clear {
    $elements_count = 0;
    @elements       = ();
    %groups         = ();
    %relations      = ();
    $ReadHead       = 0;
}

# method: init
#   Given the options ref, initializes the workspace
#
# exceptions:
#   none

sub init {
    my ( $package, $OPTIONS_ref ) = @_;
    $package->clear();
    my @seq = @{ $OPTIONS_ref->{seq} };
    for (@seq) {

        # print "Inserting '$_'\n";
        _insert_element($_);
    }
    @Global::RealSequence = @seq;
}

sub set_future_terms {
    my ( $package, @terms ) = @_;
    push @Global::RealSequence, @terms;
}

sub insert_elements {
    shift;
    for (@_) {
        _insert_element($_);
    }
}

# section: _insert_element

# method: _insert_element(#)

# method: _insert_element($)

# method: _insert_element(SElement)

multimethod _insert_element => ('#') => sub {

    # using bogues edges, since they'd be corrected soon anyway
    my $mag = shift;
    _insert_element( SElement->create( $mag, 0 ) );
};

multimethod _insert_element => ('$') => sub {
    use Scalar::Util qw(looks_like_number);
    my $what = shift;
    if ( looks_like_number($what) ) {

        # using bogus edges; these will get fixed immediately...
        _insert_element( SElement->create( int($what), 0 ) );
    }
    else {
        die "Huh? Trying to insert '$what' into the workspace";
    }
};

multimethod _insert_element => ('SElement') => sub {
    my $elt = shift;
    $elt->set_edges( $elements_count, $elements_count );
    push( @elements, $elt );
    $elements_count++;
    %Global::ExtensionRejectedByUser = ();
};

# method: read_object
# Don't yet know how this will work... right now just returns some object at the readhead and advances it.
#
sub read_object {
    my ($package) = @_;
    my $object = _get_some_object_at($ReadHead);
    unless ($object) {
        ### Failed to read any object at ReadHead = : $ReadHead
        ### elements_count: $elements_count
        confess;
    }
    my $right_edge = $object->get_right_edge;

    if ( $right_edge == $elements_count - 1 ) {
        _saccade();
    }
    else {
        $ReadHead = $right_edge + 1;
    }

    return $object;

}

{
    my $strength_chooser = SChoose->create( { map => \&SFasc::get_strength } );

    sub read_relation {
        my ($ws) = @_;
        return $strength_chooser->( [ values %relations ] );
    }

    # method: _get_some_object_at
    # returns some object spanning that index.
    #

    sub _get_some_object_at {
        my ($idx) = @_;
        my @matching_objects =
            grep { $_->get_left_edge() <= $idx and $_->get_right_edge() >= $idx }
            ( @elements, values %groups );

        return $strength_chooser->( \@matching_objects );
    }

}

# method: display_as_text
# prints a string desciption of what's in the workspace
#
sub display_as_text {
    my ($package) = @_;
    print form "======================================================",
        " Elements:  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        join( ", ", map { $_->get_mag() } @elements ),
        "======================================================";

}

# method: _saccade
# unthought through method to saccade
#
#    Jumps to a random valid position
sub _saccade {
    my $random_pos = int( rand() * $elements_count );
    $ReadHead = $random_pos;
}

# method: add_reln
#
#
sub add_reln {
    my ( $package, $reln ) = @_;
    SErr->throw("policy violation in reln add")
        unless _check_policy( 'rel_add', $reln );
    $relations{$reln} = $reln;
}

sub remove_reln {
    my ( $package, $reln ) = @_;
    SErr->throw("policy violation in rel_rem")
        unless _check_policy( 'rel_rem', $reln );
    delete $relations{$reln};
}

# method: is_there_a_covering_group
# given the range, says yes or no
#
sub is_there_a_covering_group {
    my ( $self, $left, $right ) = @_;
    foreach ( values %groups ) {
        my ( $l, $r ) = $_->get_edges;
        return $_ if ( $l <= $left and $r >= $right );
    }
    return 0;
}

sub get_all_covering_groups {
    my ( $self, $left, $right ) = @_;

    return grep {
        my ( $l, $r ) = $_->get_edges;
        $l <= $left and $r >= $right
    } values %groups;
}

sub get_all_groups_with_exact_span {
    my ( $self, $left, $right ) = @_;

    return grep {
        my ( $l, $r ) = $_->get_edges;
        $l == $left and $r == $right
    } values %groups;
}

sub get_groups_starting_at {
    my ( $self, $left ) = @_;
    my @ret;

    foreach ( values %groups ) {
        my ( $l, $r ) = $_->get_edges;
        push( @ret, $_ ) if ( $l == $left );
    }
    return rikeysort { $_->get_right_edge() } @ret;
}

sub get_longest_non_adhoc_object_starting_at {
    my ( $self, $left ) = @_;
    for my $gp ( $self->get_groups_starting_at($left) ) {    # That gives us longest first.
    INNER: for my $cat ( @{ $gp->get_categories() } ) {
            if ( $cat->get_name() !~ m#ad_hoc_# ) {
                return $gp;
            }
        }
    }

    # Getting here means no group. Return the element.
    return $elements[$left];
}

# XXX(Board-it-up): [2006/09/27] Need tests. Really.
sub get_intervening_objects {
    my ( $self, $l, $r ) = @_;
    my @ret;
    my $left = $l;
    ##  $left, $r
    while ( $left <= $r ) {
        my $o = SWorkspace->get_longest_non_adhoc_object_starting_at($left);
        push @ret, $o;
        ##  $o
        $left = $o->get_right_edge() + 1;
        ## $left
    }
    return @ret if ( $left == $r + 1 );    # Not overshot
    return;                                # overshot
}

sub add_group {
    my ( $self, $gp ) = @_;
    SErr->throw("policy violation in gp add")
        unless _check_policy( 'gp_add', $gp );
    ## $gp
    $groups{$gp} = $gp;
}

sub remove_gp {
    my ( $self, $gp ) = @_;
    SErr->throw("policy violation in gp add")
        unless _check_policy( 'gp_rem', $gp );
    delete $groups{$gp};
}

# method: check_at_location
# checks if this is the object present at a location
#
#    Arguments are start, direction(+1 or -1) and what the object to look for is.
sub check_at_location {
    my ( $self, $opts_ref ) = @_;
    my $direction = $opts_ref->{direction} || die "need direction";
    confess "Need start" unless defined $opts_ref->{start};
    my $start     = $opts_ref->{start};
    my $what      = $opts_ref->{what};
    my @flattened = @{ $what->get_flattened };
    my $span      = scalar(@flattened);

    ## $direction, $start, $what
    ## @flattened
    if ( $direction eq DIR::RIGHT() ) {    # rightward
        my $current_pos = $start - 1;
        my @already_validated;
        while (@flattened) {
            $current_pos++;
            if ( $current_pos >= $elements_count ) {

                # already out of range!
                my $err = SErr::AskUser->new(
                    already_matched => [@already_validated],
                    next_elements   => [@flattened],
                );
                $err->throw();
            }
            else {
                ## expecting: $flattened[0]
                ## got: $elements[$current_pos]->get_mag()
                if ( $elements[$current_pos]->get_mag() == $flattened[0] ) {
                    push @already_validated, shift(@flattened);
                }
                else {
                    return;
                }
            }
        }
        return 1;
    }
    else {
        if ( $span > $start + 1 ) {
            return;
        }
        for my $p ( 0 .. $span - 1 ) {
            ## $span, $start, $p, $start-$span+$p+1
            return unless $elements[ $start - $span + $p + 1 ]->get_mag() == $flattened[$p];
        }
        return 1;
    }

}

multimethod plonk_into_place => ( '#', 'DIR', 'SElement' ) => sub {
    my ( $start, $direction, $el ) = @_;
    my $el_in_ws = $SWorkspace::elements[$start];
    confess "unable to plonk!" unless $el_in_ws->get_mag() == $el->get_mag();
    return $el_in_ws;
};

multimethod plonk_into_place => ( '#', 'DIR', 'SObject' ) => sub {
    my ( $start, $dir, $obj ) = @_;
    my $span = $obj->get_span;

    if ( $dir eq DIR::LEFT() ) {
        return if $start - $span + 1 < 0;
        return plonk_into_place( $start - $span + 1, DIR::RIGHT(), $obj );
    }

    my @to_insert = ( $obj->get_direction() eq DIR::LEFT() ) ? reverse(@$obj) : @$obj;
    my $plonk_cursor = $start;
    my @new_parts;

    for my $subobject (@to_insert) {
        my $subobjectspan = $subobject->get_span;
        push @new_parts, plonk_into_place( $plonk_cursor, DIR::RIGHT(), $subobject );
        $plonk_cursor += $subobjectspan;
    }

    @new_parts = reverse(@new_parts) if ( $obj->get_direction() eq DIR::LEFT() );

    my $new_obj                  = SAnchored->create(@new_parts);
    my $new_obj_structure_string = $new_obj->get_structure_string;

    my $old_obj;
    ## $new_obj_structure_string
    for my $spanning_obj ( SWorkspace->get_all_covering_groups( $start, $start + $span - 1 ) ) {
        ## $spanning_obj
        if ( $spanning_obj->get_structure_string() eq $new_obj_structure_string ) {
            $old_obj = $spanning_obj;
            ## $old_obj
            last;
        }
    }

    if ($old_obj) {
        $new_obj = $old_obj;
    }
    else {
        SWorkspace->add_group($new_obj);
    }

    my $rel_scheme = $obj->get_reln_scheme;
    if ($rel_scheme) {
        $new_obj->apply_reln_scheme($rel_scheme);
    }

    for ( @{ $obj->get_categories() } ) {
        my $bindings     = $new_obj->describe_as($_) or confess "Description failed";
        my $old_bindings = $obj->describe_as($_);
        my $old_pos_mode = $old_bindings->get_position_mode();
        if ( defined $old_pos_mode ) {
            $bindings->TellDirectedStory( $new_obj, $old_pos_mode );
        }
    }

    if ( my $metonym = $obj->get_metonym() ) {
        my ( $cat, $name ) = ( $metonym->get_category(), $metonym->get_name() );
        $new_obj->annotate_with_metonym( $cat, $name );
        $new_obj->set_metonym_activeness( $obj->get_metonym_activeness );
    }
    return $new_obj;

};

# method: _check_policy
#
#
sub _check_policy {
    my ( $name, @args ) = @_;
    my $code = $POLICY{$name} || SErr->throw("unknown policy");
    return $code->(@args);
}

sub rapid_create_gp {
    my ( $self, $cats, @items ) = @_;
    @items = map {
        if ( ref($_) eq "ARRAY" )
        {
            $self->rapid_create_gp(@$_);
        }
        else {
            $_;
        }
    } @items;

    my $object = SAnchored->create(@items);
    SWorkspace->add_group($object);

    while (@$cats) {
        my $next = shift(@$cats);
        if ( $next eq "metonym" ) {
            my $cat  = shift(@$cats);
            my $name = shift(@$cats);
            $object->describe_as($cat);
            $object->annotate_with_metonym( $cat, $name );
            $object->set_metonym_activeness(1);
        }
        else {
            $object->describe_as($next);
        }
    }
    return $object;
}

sub are_there_holes_here {
    my ( $self, @items ) = @_;
    my %slots_taken;
    for my $item (@items) {
        SErr->throw("SAnchored->create called with a non anchored object")
            unless UNIVERSAL::isa( $item, "SAnchored" );
        my ( $left, $right ) = $item->get_edges();
        @slots_taken{ $left .. $right } = ( $left .. $right );
    }

    my @keys = values %slots_taken;
    ## @keys
    my ( $left, $right )
        = List::MoreUtils::minmax( $keys[0], @keys )
        ;    #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    ## $left, $right
    my $span = $right - $left + 1;

    unless ( scalar(@keys) == $span ) {
        return 1;
    }
    return 0;
}

1;

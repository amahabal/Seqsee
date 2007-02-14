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
use English qw(-no_match_vars);

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
our %relations_by_ends;    # keys: end1;end2 value:1 if a relation present.

my $strength_chooser = SChoose->create( { map => \&SFasc::get_strength } );

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
    $Global::InitialTermCount = scalar(@seq);
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
    $Global::TimeOfLastNewElement = $Global::Steps_Finished;
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
        _saccade();
        return read_object();
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

# method: AddRelation
#
#
sub AddRelation {
    my ( $package, $reln ) = @_;
    my ( $f,       $s )    = $reln->get_ends();
    my $key = join( ';', $f, $s );
    return if exists $relations_by_ends{$key};

    #my $key_r = join(';', $s, $f);
    #confess 'reverse relation exists!' if exists $relations_by_ends{$key_r};

    $relations_by_ends{$key} = 1;
    $relations{$reln}        = $reln;
}

sub RemoveRelation {
    my ( $package, $reln ) = @_;

    my $key = join( ';', $reln->get_ends() );
    delete $relations_by_ends{$key};

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

sub get_all_groups_within {
    my ( $self, $left, $right ) = @_;

    return grep {
        my ( $l, $r ) = $_->get_edges;
        $left <= $l and $r <= $right
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
    for my $gp ( $self->get_groups_starting_at($left) )
    {    # That gives us longest first.
      INNER: for my $cat ( @{ $gp->get_categories() } ) {
            if ( $cat->get_name() !~ m#ad_hoc_# ) {
                return $gp;
            }
        }
    }

    if ($left >= $elements_count) {
        ### left: $left
        ### elements_count: $elements_count
        confess "Why am I being asked this?";
    }
    # Getting here means no group. Return the element.
    return $elements[$left];
}

sub AreGroupsInConflict {
    my ( $package, $A, $B ) = @_;
    return 1 if $A eq $B;

    my ( $smaller, $bigger ) =
      sort { $a->get_span() <=> $b->get_span() } ( $A, $B );

    return 0 if $smaller->isa('SElement');    # Never conflicts!
    return 0 unless $bigger->spans($smaller); # obvious case.

    my ( $smaller_left_edge, $smaller_right_edge ) = $smaller->get_edges();
    ## smaller_edges: $smaller_left_edge, $smaller_right_edge

    my $current_position = -1;
    for my $biggers_piece (@$bigger) {
        $current_position++;
        next if $biggers_piece->get_right_edge() < $smaller_left_edge;

        # No "backtracking" beyond here. If @$smaller is a subset of @$bigger,
        # it must start here! So no "next" here on.
        ## $current_position: $current_position

        for my $smallers_piece (@$smaller) {
            return 0 unless $smallers_piece eq $bigger->[$current_position];
            $current_position++;
        }

        # No mismatch detected!
        return 1;    # Conflicts!
    }
    confess "Why am I here?"; # if bigger spans smaller, no business being here!
}

sub AreGroupsInConflict_helper {
    my ( $package, $smaller, $bigger ) = @_;
    return 0 if $smaller eq $bigger;
    return 1 unless $bigger->spans($smaller);

    my ( $smaller_left_edge, $smaller_right_edge ) = $smaller->get_edges();
    for my $piece_of_bigger (@$bigger) {
        my ( $piece_left_edge, $piece_right_edge ) =
          $piece_of_bigger->get_edges();
        next
          if $piece_right_edge <
          $smaller_left_edge;    # piece too early within bigger. Look ahead.
        ## If we are here, the current piece must be $smaller, or have $smaller as part.
        return $package->AreGroupsInConflict_helper( $smaller,
            $piece_of_bigger );
    }
    confess "Why am I here?";
}

sub FindGroupsConflictingWith {
    my ( $package, $object ) = @_;
    my ( $l,       $r )      = $object->get_edges();
    my $exact_conflict;

    my @exact_span = SWorkspace->get_all_groups_with_exact_span( $l, $r );
    my $structure_string = $object->get_structure_string();
    my @exact_span_same_structure =
      grep { $_->get_structure_string() eq $structure_string } @exact_span;

    if (@exact_span_same_structure) {
        $exact_conflict = $exact_span_same_structure[0]; # Can only ever be one.
    }

    my @conflicting = grep {
        ## Conflict check: ident($object), $object->get_bounds_string(), ident($_), $_->get_bounds_string()
        SWorkspace->AreGroupsInConflict( $object, $_ );
      } (
        SWorkspace->get_all_covering_groups( $l, $r ),
        SWorkspace->get_all_groups_within( $l, $r )
      );
    ## @conflicting: @conflicting

    # @conflicting will also contain $exact_conflict, but that is fine.
    return ( $exact_conflict, @conflicting );
}

# XXX(Board-it-up): [2006/09/27] Need tests. Really.
sub get_intervening_objects {
    my ( $self, $l, $r ) = @_;
    my @ret;
    my $left = $l;
    ##  $left, $r
    if ($r >= $elements_count) {
        confess "get_intervening_objects called with right end of gap beyond known elements";
    }
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
    my ( $exact_conflict, @subset_conflicts ) =
      SWorkspace->FindGroupsConflictingWith($gp);
    ## $exact_conflict, @subset_conflicts: $exact_conflict, @subset_conflicts
    return 0 if $exact_conflict;

    if (@subset_conflicts) {
        my $one_conflict = shift(@subset_conflicts);
        ## $one_conflict: ident($one_conflict)
        if (
            SWorkspace->FightUntoDeath(
                {
                    challenger => $gp,
                    incumbent  => $one_conflict
                }
            )
          )
        {

            ## So the incumbent was defeated!
            # Now pretend that the other group never existed...
            return SWorkspace->add_group($gp);
        }
        else {
            ## Incumbent lives!
            return 0;
        }
    }

    $groups{$gp} = $gp;
    return 1;
}

sub remove_gp {
    my ( $self, $gp ) = @_;
    DeleteGroupsContaining($gp);
}

sub DeleteGroupsContaining{
    my ( $member_object ) = @_;
    for my $gp (values %groups) {
        DeleteGroupsContaining($gp) if $gp->HasAsItem($member_object);
    }
    $member_object->RemoveAllRelations();
    delete $groups{$member_object};
}


sub UpdateGroupsContaining{
    my ( $member_object ) = @_;
    for my $gp (values %groups) {
        $gp->Update() if $gp->HasAsItem($member_object);
    }
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
        CheckElementsRightwardFromLocation( $start, \@flattened,
                                            $what, $start, $direction
                                                );
    } elsif ($direction eq $DIR::LEFT) {
        
        if ( $span > $start + 1 ) { # would extend beyond left edge
            return;
        }

        my $left_end_of_potential_match = $start - $span + 1;
        return CheckElementsRightwardFromLocation($left_end_of_potential_match,
                                                  \@flattened,
                                                  $what, $start, $direction 
                                                      );
    } else {
        confess "Huh?";
    }

}

sub CheckElementsRightwardFromLocation{
    my ( $start, $elements_ref,
         $object_being_looked_for,
         $position_it_is_being_looked_from,
         $direction_to_look_in) = @_;
    my @flattened = @$elements_ref;
    my $current_pos = $start - 1;
    my @already_validated;
    while (@flattened) {
        $current_pos++;
        if ( $current_pos >= $elements_count ) {
            # already out of range!
            my $err = SErr::AskUser->new(
                already_matched => [@already_validated],
                next_elements   => [@flattened],
                object => $object_being_looked_for,
                from_position => $position_it_is_being_looked_from,
                direction => $direction_to_look_in
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

    my @to_insert =
      ( $obj->get_direction() eq DIR::LEFT() ) ? reverse(@$obj) : @$obj;
    my $plonk_cursor = $start;
    my @new_parts;

    for my $subobject (@to_insert) {
        my $subobjectspan = $subobject->get_span;
        push @new_parts,
          plonk_into_place( $plonk_cursor, DIR::RIGHT(), $subobject );
        $plonk_cursor += $subobjectspan;
    }

    @new_parts = reverse(@new_parts)
      if ( $obj->get_direction() eq DIR::LEFT() );

    my $new_obj                  = SAnchored->create(@new_parts);
    my $new_obj_structure_string = $new_obj->get_structure_string;

    my $old_obj;
    ## $new_obj_structure_string
    for my $spanning_obj (
        SWorkspace->get_all_covering_groups( $start, $start + $span - 1 ) )
    {
        ## $spanning_obj: $spanning_obj->get_structure_string()
        ## new_obj_structure_string: $new_obj_structure_string
        if (
            $spanning_obj->get_structure_string() eq $new_obj_structure_string )
        {
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
        my $bindings = $new_obj->describe_as($_)
          or confess "Description failed";
        my $old_bindings = $obj->describe_as($_);
        my $old_pos_mode = $old_bindings->get_position_mode();
        if ( defined $old_pos_mode ) {
            $bindings->TellDirectedStory( $new_obj, $old_pos_mode );
        }
    }

    if ( my $metonym = $obj->get_metonym() ) {
        my ( $cat, $name ) = ( $metonym->get_category(), $metonym->get_name() );
        $new_obj->AnnotateWithMetonym( $cat, $name );
        $new_obj->SetMetonymActiveness( $obj->get_metonym_activeness );
    }
    return $new_obj;

};

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
            $object->AnnotateWithMetonym( $cat, $name );
            $object->SetMetonymActiveness(1);
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
    my ( $left, $right ) =
      List::MoreUtils::minmax( $keys[0], @keys )
      ; #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    ## $left, $right
    my $span = $right - $left + 1;

    unless ( scalar(@keys) == $span ) {
        return 1;
    }
    return 0;
}

sub FightUntoDeath {
    my ( $package, $opts_ref ) = @_;
    my ( $challenger, $incumbent ) =
      ( $opts_ref->{challenger}, $opts_ref->{incumbent} );
    my (@strengths) = map { $_->get_strength() } ( $challenger, $incumbent );
    confess "Both strengths 0" unless $strengths[0] + $strengths[1];
    if (
        SUtil::toss( $strengths[0] / ( $strengths[0] + 1.5 * $strengths[1] ) ) )
    {

        # challenger won!
        SWorkspace->remove_gp($incumbent);
        return 1;
    }
    else {

        # incumbent won!
        return 0;
    }
}

sub GetSomethingLike {
    my ( $package, $opts_ref ) = @_;
    my $object    = $opts_ref->{object} or confess;
    my $start_pos = $opts_ref->{start};
    my $direction = $opts_ref->{direction} or confess;
    my $reason    = $opts_ref->{reason} || ''; # used for message for ask_user
    my $trust_level = $opts_ref->{trust_level} or confess; # used if ask_user
    defined($start_pos) or confess;

    my @objects_at_that_location;
    if ( $direction eq $DIR::RIGHT ) {
        @objects_at_that_location =
          grep { $_->get_left_edge() eq $start_pos }
          ( @elements, values %groups );
    }
    elsif ( $direction eq $DIR::LEFT ) {
        @objects_at_that_location =
          grep { $_->get_right_edge() eq $start_pos }
          ( @elements, values %groups );
    }

    my $expected_structure_string = $object->get_structure_string();

    my ( @matching_objects, @potentially_matching_objects );
    for (@objects_at_that_location) {
        if ( $_->GetEffectiveObject()->get_structure_string() eq
            $expected_structure_string )
        {
            push @matching_objects, $_;
        }
        else {
            push @potentially_matching_objects, $_;
        }
    }

    my $is_object_literally_present = eval {
        SWorkspace->check_at_location(
            { direction => $direction, start => $start_pos, what => $object } );
    };

    if ( my $e = $EVAL_ERROR ) {
        if ( UNIVERSAL::isa( $e, 'SErr::AskUser' ) ) {

            # XXX(Board-it-up): [2006/12/18]
            if ( $e->WorthAsking($trust_level) ) {
                $e->Ask($reason);
            }
        }
        else {
            die $e;
        }
    }

    if ($is_object_literally_present) {
        my $present_object =
          plonk_into_place( $start_pos, $direction, $object );
        if ( SUtil::toss(0.5) ) {
            return $present_object;
        }
        else {
            push @matching_objects, $present_object;
        }
    }

    for (@potentially_matching_objects) {
        SCoderack->add_codelet(
            SCodelet->new(
                'TryToSquint',
                50,
                {
                    actual   => $_,
                    intended => $object,
                }
            )
        );
    }

    return $strength_chooser->( \@matching_objects );
}

sub SErr::AskUser::WorthAsking {
    my ( $self, $trust_level ) = @_;
    my ($match_size, $ask_size) = (scalar(@{$self->already_matched()}),
                                   scalar(@{$self->next_elements()}));
    my $fraction_already_matched = $match_size / ($match_size + $ask_size);
    $trust_level += (1 - $trust_level) * $fraction_already_matched; 
    return SUtil::toss($trust_level) ? 1 : 0;
}

sub SErr::AskUser::Ask {
    my ( $self, $msg ) = @_;
    my $already_matched = $self->already_matched();
    my $next_elements   = $self->next_elements();

    my $object_being_looked_for = $self->object();
    my $position_it_is_being_looked_from = $self->from_position();
    my $direction_to_look_in = $self->direction();

    if (@$already_matched) {
        $msg .=
          "I also found the expected terms " . join( ', ', @$already_matched );
    }

    my $answer =  main::ask_user_extension( $next_elements, $msg );
    if ($answer) {
        SWorkspace->insert_elements( @$next_elements );
        main::update_display();
        $Global::Break_Loop = 1;

        if (defined $object_being_looked_for) {
            plonk_into_place($position_it_is_being_looked_from,
                             $direction_to_look_in,
                             $object_being_looked_for
                                 );
        }

    } else {
        my $seq = join(', ', @$next_elements);
        $Global::ExtensionRejectedByUser{ $seq } = 1;
    }
    return $answer;
}

1;

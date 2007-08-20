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
use List::Util;
use base qw{};

use Perl6::Form;
use Smart::Comments;
use English qw(-no_match_vars);

use Sort::Key qw{rikeysort ikeysort};

# Seqsee packages. Fix.
use ResultOfGetConflicts;
use ResultOfAttributeCopy;
use ResultOfPlonk;

#=============================================
#=============================================
# NEW CODE
#=============================================

my $ElementCount = 0;
my @Elements;
my @ElementMagnitudes;
my %Objects;          # List of all objects.
my %NonEltObjects;    # Only groups (of size 2 or more)

my %LeftEdge_of;      # Maintains left edges of "registered" groups.
my %RightEdge_of;     # Likewise, right edges.
my %SuperGroups_of;   # Groups whose direct element is this group.
my %Span_of;          # Span.

sub GetElements {
    my ($package) = @_;
    return @Elements;
}

sub GetGroups {
    my ($package) = @_;
    return rikeysort { $Span_of{$_} } values %NonEltObjects;
}

sub __Clear {
    $ElementCount   = 0;
    @Elements       = @ElementMagnitudes = %Objects = %NonEltObjects = ();
    %LeftEdge_of    = %RightEdge_of = ();
    %SuperGroups_of = %Span_of = ();
}

sub __CheckLiveness {
    exists( $Objects{ $_[0] } ) ? 1 : 0;
}

sub __CheckLivenessAndDiagnose {
    my $problems_so_far = 0;
    for my $object (@_) {
        next if exists( $Objects{$object} );

        # So a dead object!
        my $unstarred = $object->get_unstarred();
        if ( $unstarred ne $object ) {
            print "A METONYM IS BEING CHECKED FOR LIVENESS!\n";
            if ( exists $Objects{$unstarred} ) {
                print "\tIts unstarred *is* live.\n";
            }
            else {
                print "\tEven its unstarred is non-live.\n";
            }
        }
        $problems_so_far++;
    }
    return $problems_so_far ? 0 : 1;
}

sub __GrepLiveness {
    grep { exists( $Objects{$_} ) } @_;
}

sub __GetObjectsWithEndsExactly {
    my ( $left, $right ) = @_;
    my @objects = values %Objects;
    if ( defined $left ) {
        @objects = grep { $LeftEdge_of{$_} == $left } @objects;
    }
    if ( defined $right ) {
        @objects = grep { $RightEdge_of{$_} == $right } @objects;
    }
    return @objects;
}

sub __GetObjectsWithEndsBeyond {
    my ( $left, $right ) = @_;
    my @objects = values %Objects;
    if ( defined $left ) {
        @objects = grep { $LeftEdge_of{$_} <= $left } @objects;
    }
    if ( defined $right ) {
        @objects = grep { $RightEdge_of{$_} >= $right } @objects;
    }
    return @objects;
}

sub __GetObjectsWithEndsNotBeyond {
    my ( $left, $right ) = @_;
    my @objects = values %Objects;
    if ( defined $left ) {
        @objects = grep { $LeftEdge_of{$_} >= $left } @objects;
    }
    if ( defined $right ) {
        @objects = grep { $RightEdge_of{$_} <= $right } @objects;
    }
    return @objects;
}

sub __GetExactObjectIfPresent {
    my ($object) = @_;
    my ( $left, $right ) = $object->get_edges();

    my $structure_string = $object->get_structure_string();
    my @matching = grep { $_->get_structure_string() eq $structure_string }
        __GetObjectsWithEndsExactly( $left, $right );
    return unless @matching;
    return $matching[0];    # There can be only one.
}

sub __SortLtoRByLeftEdge {
    ### require: __CheckLivenessAndDiagnose(@_)
    return ikeysort { $LeftEdge_of{$_} } @_;
}

sub __SortRtoLByLeftEdge {
    ### require: __CheckLivenessAndDiagnose(@_)
    return rikeysort { $LeftEdge_of{$_} } @_;
}

sub __SortLtoRByRightEdge {
    ### require: __CheckLivenessAndDiagnose(@_)
    return ikeysort { $RightEdge_of{$_} } @_;
}

sub __SortRtoLByRightEdge {
    ### require: __CheckLivenessAndDiagnose(@_)
    return rikeysort { $RightEdge_of{$_} } @_;
}

sub __DeleteGroup {
    my ($group) = @_;
    my @super_groups = values %{ $SuperGroups_of{$group} };

    for my $super_group (@super_groups) {
        next unless __CheckLiveness($super_group);
        __DeleteGroup($super_group);
    }

    for my $part (@$group) {
        delete $SuperGroups_of{$part}{$group};
    }

    # __RemoveRelations_of($group);
    delete $LeftEdge_of{$group};
    delete $RightEdge_of{$group};
    delete $Span_of{$group};
    delete $SuperGroups_of{$group};
    delete $Objects{$group};
    delete $NonEltObjects{$group};
}

multimethod __InsertElement => ('SElement') => sub {
    my ($element) = @_;
    my $magnitude = $element->get_mag();

    $element->set_edges( $ElementCount, $ElementCount );
    push @Elements,          $element;
    push @ElementMagnitudes, $magnitude;
    Global::UpdateExtensionsRejectedByUser($magnitude);

    $LeftEdge_of{$element}    = $ElementCount;
    $RightEdge_of{$element}   = $ElementCount;
    $Span_of{$element}        = 1;
    $Objects{$element}        = $element;
    $SuperGroups_of{$element} = {};

    $ElementCount++;
};

sub __CheckTwoGroupsForConflict {    # Second must be live.
    my ( $A, $B ) = @_;

    return 1 if $A eq $B;
    if ( !__CheckLiveness($B) ) {
        confess "This method only works when the second object is live";
    }

    my ( $smaller, $bigger ) = ikeysort { $_->get_span() } ( $A, $B );
    return 0 if $smaller->isa('SElement');
    return 0 unless $bigger->spans($smaller);

    my $smaller_left_edge = $smaller->get_left_edge();
    my $current_index     = -1;
    for my $piece_of_bigger (@$bigger) {
        $current_index++;
        next if $RightEdge_of{$piece_of_bigger} < $smaller_left_edge;

        # No "backtracking" beyond here. If @$smaller is a subset of @$bigger,
        # it must start here! So no "next" here on.

        # If @$smaller is indeed a subset of @$bigger, the pieces must match...
        for my $piece_of_smaller (@$smaller) {
            return 0 unless $piece_of_smaller eq $bigger->[$current_index];
            $current_index++;
        }

        # If we reach here, then all smaller pieces match a bigger piece.
        # smaller and bigger may also have exactly the same elements (i.e., not "proper" subset)
        # but the conflict exists!
        return 1;
    }
    confess "Should never reach here.";
}

sub __GroupAddSanityCheck {
    my (@parts) = @_;
    ### require: __CheckLivenessAndDiagnose(@_)
    return 0 if __AreHolesPresent(@parts);
}

sub __DoGroupAddBookkeeping {
    my ($group) = @_;

    # Assuming sanity checks passed.
    $Objects{$group}        = $group;
    $NonEltObjects{$group}  = $group;
    $SuperGroups_of{$group} = {};
    __UpdateGroup($group);
}

# When a group shortens, I am going to have trouble with false super_group data...
# So carefully call __RemoveFromSupergroups_of
sub __UpdateGroup {
    my ($group) = @_;

    # Assume that if $group has changed, $SuperGroups_of{$group} was empty.
    my @parts = @$group;
    for my $part (@parts) {
        $SuperGroups_of{$part}{$group} = $group;
    }

    # I can assume that all parts are live...
    my $left_edge  = List::Util::min( @LeftEdge_of{@parts} );
    my $right_edge = List::Util::max( @RightEdge_of{@parts} );
    $LeftEdge_of{$group}  = $left_edge;
    $RightEdge_of{$group} = $right_edge;
    $Span_of{$group}      = $right_edge - $left_edge + 1;

}

sub __RemoveFromSupergroups_of {
    my ( $subgroup, $supergroup ) = @_;
    delete $SuperGroups_of{$subgroup}{$supergroup};
}

sub __FindObjectSetDirection {
    my (@objects) = @_;
    ### require: __CheckLivenessAndDiagnose(@_)

    # Assumption: @objects are live.
    my @left_edges = map { $LeftEdge_of{$_} } @objects;
    my $how_many = scalar(@objects);
    confess "Need at least 2" if $how_many <= 1;

    my ( $leftward, $rightward );
    for ( 0 .. $how_many - 2 ) {
        my $diff = $left_edges[ $_ + 1 ] - $left_edges[$_];
        if ( $diff > 0 ) {
            $rightward++;
        }
        elsif ( $diff < 0 ) {
            $leftward++;
        }
        else {
            return $DIR::UNKNOWN;
        }
    }

    return $DIR::NEITHER if ( $leftward and $rightward );
    return $DIR::LEFT    if $leftward;
    return $DIR::RIGHT   if $rightward;
    confess "huh?";
}

sub __AreThereHolesOrOverlap {
    my (@parts) = @_;
    ### require: __CheckLivenessAndDiagnose(@_)

    # Assumption: All @parts live
    my $direction = __FindObjectSetDirection(@parts);
    if ( $direction eq $DIR::RIGHT ) {
        for my $idx ( 0 .. scalar(@parts) - 2 ) {
            $RightEdge_of{ $parts[$idx] } + 1 == $LeftEdge_of{ $parts[ $idx + 1 ] }
                or return 1;    # Hole/overlap present
        }
        return 0;               # No holes, no overlap.
    }
    elsif ( $direction eq $DIR::LEFT ) {
        for my $idx ( 0 .. scalar(@parts) - 2 ) {
            $LeftEdge_of{ $parts[$idx] } - 1 == $RightEdge_of{ $parts[ $idx + 1 ] }
                or return 1;    # Hole/overlap present
        }
        return 0;               # No holes, no overlap.
    }
    else {
        return 1;   # funny direction, so question of holes is moot. This cannot make a good object.
    }
}

sub __CheckMagnitudesRightwards {
    my ( $start_position, $expected_magnitudes_ref ) = @_;
    my $next_position_to_check = $start_position;
    my @expected_magnitudes    = @{$expected_magnitudes_ref};
    my @already_validated;

    while (@expected_magnitudes) {
        my $next_magnitude_expected = shift(@expected_magnitudes);
        if ( $next_position_to_check >= $ElementCount ) {

            # throw!
            SErr::AskUser->throw(
                already_matched => \@already_validated,
                next_elements   => \@expected_magnitudes,
            );
        }
        elsif ( $ElementMagnitudes[$next_position_to_check] == $next_magnitude_expected ) {
            $next_position_to_check++;
            push @already_validated, $next_magnitude_expected;
        }
        else {
            return 0;    # Failed! Those are not the next elements.
        }
    }

    return 1;            # Yes, right elements.
}

sub __FindGroupsConflictingWith {
    my ($object) = @_;
    my ( $l, $r ) = $object->get_edges();

    my @exact_span = __GetObjectsWithEndsExactly( $l, $r );
    my $structure_string = $object->get_structure_string();
    my ($exact_conflict) =    # Can only ever be one.
        grep { $_->get_structure_string() eq $structure_string } @exact_span;
    $exact_conflict ||= '';

    my @conflicting =
        grep { $_ ne $exact_conflict }
        grep { __CheckTwoGroupsForConflict( $object, $_ ) }
        ( __GetObjectsWithEndsBeyond( $l, $r ), __GetObjectsWithEndsNotBeyond( $l, $r ) );
    ## @conflicting: @conflicting
    return ResultOfGetConflicts->new(
        {   original => $object,
            exact    => $exact_conflict,
            other    => \@conflicting,
        }
    );
}

sub __CopyAttributes {
    my ($opts_ref) = @_;
    my ( $from, $to ) = ( $opts_ref->{from}, $opts_ref->{to} );
    if ( !$from or !$to ) {
        die "Missing from or to";
    }

    my $any_failure_so_far = 0;

    # Copy Metonym:
    if ( my $metonym = $from->get_metonym() ) {
        my ( $cat, $name ) = ( $metonym->get_category(), $metonym->get_name() );
        $to->AnnotateWithMetonym( $cat, $name );
        $to->SetMetonymActiveness( $from->get_metonym_activeness() );
    }

    # Relation Scheme:
    if ( my $rel_scheme = $from->get_reln_scheme() ) {
        $to->apply_reln_scheme($rel_scheme);
    }

    # Copy groupness:
    $to->set_group_p(1) if $from->get_group_p();

    # Copy Categories:
    for my $category ( @{ $from->get_categories() } ) {
        my $bindings;
        unless ( $bindings = $to->describe_as($category) ) {
            $any_failure_so_far++;
            next;
        }
        my $bindings_for_from      = $from->describe_as($category);
        my $position_mode_for_from = $bindings_for_from->get_position_mode();
        if ( defined $position_mode_for_from ) {
            $bindings->TellDirectedStory( $to, $position_mode_for_from );
        }
    }
    if ($any_failure_so_far) {
        return ResultOfAttributeCopy->Failed();
    }
    else {
        return ResultOfAttributeCopy->Success();
    }
}

multimethod __PlonkIntoPlace => ( '#', 'DIR', 'SElement' ) => sub {
    my ( $start, $direction, $element ) = @_;
    *__ANON__ = '__ANON__PlonkIntoPlace_el';
    my $magnitude = $element->get_mag();

    unless ( $magnitude == $ElementMagnitudes[$start] ) {
        return ResultOfPlonk->Failed($element);
    }

    my $attribute_copy_result = __CopyAttributes(
        {   from => $element,
            to   => $Elements[$start],
        }
    );
    return ResultOfPlonk->new(
        {   object_being_plonked  => $element,
            resultant_object      => $Elements[$start],
            attribute_copy_result => $attribute_copy_result,
        }
    );
};

multimethod __PlonkIntoPlace => ( '#', 'DIR', 'SObject' ) => sub {
    my ( $start, $direction, $object ) = @_;
    *__ANON__ = '__ANON__PlonkIntoPlace_obj';

    my $span = $object->get_span() or return ResultOfPlonk->Failed($object);

    if ( $direction eq $DIR::LEFT ) {
        return ResultOfPlonk->Failed($object) if $start < $span - 1;
        return __PlonkIntoPlace( $start - $span + 1, $DIR::RIGHT, $object );
    }

    my @to_insert = ( $object->get_direction() eq $DIR::LEFT ) ? reverse(@$object) : @$object;
    my @new_parts;
    my $plonk_cursor                 = $start;
    my $attribute_copy_status_so_far = ResultOfAttributeCopy->Success();

    for my $subobject (@to_insert) {
        my $subobjectspan = $subobject->get_span;
        my $plonk_result = __PlonkIntoPlace( $plonk_cursor, $DIR::RIGHT, $subobject );
        if ( $plonk_result->PlonkWasSuccessful() ) {
            push @new_parts, $plonk_result->get_resultant_object();
            $plonk_cursor += $subobjectspan;
            $attribute_copy_status_so_far->UpdateWith( $plonk_result->get_attribute_copy_result );
        }
        else {
            return ResultOfPlonk->Failed($object);
        }
    }

    my $new_obj = SAnchored->create(@new_parts);
    if ( my $existing_object = __GetExactObjectIfPresent($new_obj) ) {
        $new_obj = $existing_object;
    }
    else {
        if ( !SWorkspace->add_group($new_obj) ) {
            return ResultOfPlonk->Failed($object);
        }
    }

    my $attribute_copy_result = __CopyAttributes(
        {   from => $object,
            to   => $new_obj,
        }
    );
    $attribute_copy_status_so_far->UpdateWith($attribute_copy_result);
    return ResultOfPlonk->new(
        {   object_being_plonked  => $object,
            resultant_object      => $new_obj,
            attribute_copy_result => $attribute_copy_status_so_far,
        }
    );

};

#=============================================
#=============================================

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

    __Clear();
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
    @Global::RealSequence     = @seq;
    $Global::InitialTermCount = scalar(@seq);
}

sub insert_elements {
    shift;
    for (@_) {
        _insert_element($_);
    }
    $Global::TimeOfLastNewElement = $Global::Steps_Finished;
    $Global::TimeOfNewStructure   = $Global::Steps_Finished;
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

    __InsertElement($elt);
};

# method: read_object
sub read_object {
    my ($package) = @_;
    my @choose_from;
    my @all_objects = ( @elements, values %groups );
    if ( $Global::Feature{chooseright} ) {
        @choose_from = @all_objects;
        push @choose_from, grep { $_->get_span() > 4 } @all_objects;
    }
    push @choose_from,
        grep { $_->get_left_edge() <= $ReadHead and $_->get_right_edge() >= $ReadHead }
        @all_objects;
    my $object     = $strength_chooser->( \@choose_from );
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

# method: _saccade
# unthought through method to saccade
#
#    Jumps to a random valid position
sub _saccade {
    if ( SUtil::toss(0.5) ) {
        return $ReadHead = 0;
    }
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

sub get_all_groups_within {
    my ( $self, $left, $right ) = @_;
    return __GetObjectsWithEndsNotBeyond( $left, $right );
}

sub get_all_groups_with_exact_span {
    my ( $self, $left, $right ) = @_;
    return __GetObjectsWithEndsExactly( $left, $right );
}

sub get_groups_starting_at {
    my ( $self, $left ) = @_;
    return __SortRtoLByRightEdge( __GetObjectsWithEndsExactly( $left, undef ) );
}

sub get_groups_ending_at {
    my ( $self, $right ) = @_;

    # return __SortLtoRByLeftEdge(__GetObjectsWithEndsExactly(undef, $right));
    return __GetObjectsWithEndsExactly( undef, $right );
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

    if ( $left >= $elements_count ) {
        ### left: $left
        ### elements_count: $elements_count
        confess "Why am I being asked this?";
    }

    # Getting here means no group. Return the element.
    return $elements[$left];
}

sub get_longest_non_adhoc_object_ending_at {
    my ( $self, $right ) = @_;
    for my $gp ( $self->get_groups_ending_at($right) ) {    # That gives us longest first.
    INNER: for my $cat ( @{ $gp->get_categories() } ) {
            if ( $cat->get_name() !~ m#ad_hoc_# ) {
                return $gp;
            }
        }
    }

    # Getting here means no group. Return the element.
    return $elements[$right];
}

sub AreGroupsInConflict {
    my ( $package, $A, $B ) = @_;
    return __CheckTwoGroupsForConflict( $A, $B ) if __CheckLiveness($B);
}

sub FindGroupsConflictingWith {
    my ( $package, $object ) = @_;
    my ( $l,       $r )      = $object->get_edges();

    my @exact_span = __GetObjectsWithEndsExactly( $l, $r );
    my $structure_string = $object->get_structure_string();
    my ($exact_conflict) =    # Can only ever be one.
        grep { $_->get_structure_string() eq $structure_string } @exact_span;

    my @conflicting = grep { __CheckTwoGroupsForConflict( $object, $_ ) }
        ( __GetObjectsWithEndsBeyond( $l, $r ), __GetObjectsWithEndsNotBeyond( $l, $r ) );
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
    if ( $r >= $elements_count ) {
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
    my $conflicts = __FindGroupsConflictingWith($gp);
    if ($conflicts) {
        $conflicts->Resolve( { FailIfExact => 1 } ) or return;
    }

    $groups{$gp} = $gp;
    $Global::TimeOfNewStructure = $Global::Steps_Finished;
    __DoGroupAddBookkeeping($gp);
    return 1;
}

sub remove_gp {
    my ( $self, $gp ) = @_;
    DeleteGroupsContaining($gp);
    __DeleteGroup($gp);
}

sub DeleteGroupsContaining {
    my ($member_object) = @_;
    my @groups = values %groups;
    for my $gp (@groups) {
        DeleteGroupsContaining($gp) if $gp->HasAsItem($member_object);
    }
    $member_object->RemoveAllRelations();
    delete $groups{$member_object};
}

sub UpdateGroupsContaining {
    my ($member_object) = @_;
    for my $gp ( values %groups ) {
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
        CheckElementsRightwardFromLocation( $start, \@flattened, $what, $start, $direction );
    }
    elsif ( $direction eq $DIR::LEFT ) {

        if ( $span > $start + 1 ) {        # would extend beyond left edge
            return;
        }

        my $left_end_of_potential_match = $start - $span + 1;
        return CheckElementsRightwardFromLocation( $left_end_of_potential_match,
            \@flattened, $what, $start, $direction );
    }
    else {
        confess "Huh?";
    }

}

sub CheckElementsRightwardFromLocation {
    my ( $start, $elements_ref, $object_being_looked_for, $position_it_is_being_looked_from,
        $direction_to_look_in )
        = @_;
    my @flattened   = @$elements_ref;
    my $current_pos = $start - 1;
    my @already_validated;
    while (@flattened) {
        $current_pos++;
        if ( $current_pos >= $elements_count ) {

            # already out of range!
            my $err = SErr::AskUser->new(
                already_matched => [@already_validated],
                next_elements   => [@flattened],
                object          => $object_being_looked_for,
                from_position   => $position_it_is_being_looked_from,
                direction       => $direction_to_look_in
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
    return 0 unless @items;
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

sub FightUntoDeath {
    my ( $package, $opts_ref ) = @_;
    my ( $challenger, $incumbent ) = ( $opts_ref->{challenger}, $opts_ref->{incumbent} );
    if ( !__CheckLiveness($incumbent) ) {

        # Hah. $challenger a No contest winner.
        return 1;
    }
    my (@strengths) = map { $_->get_strength() } ( $challenger, $incumbent );
    confess "Both strengths 0" unless $strengths[0] + $strengths[1];
    if ( SUtil::toss( $strengths[0] / ( $strengths[0] + 1.5 * $strengths[1] ) ) ) {

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
    my $object      = $opts_ref->{object} or confess;
    my $start_pos   = $opts_ref->{start};
    my $direction   = $opts_ref->{direction} or confess;
    my $reason      = $opts_ref->{reason} || '';              # used for message for ask_user
    my $trust_level = $opts_ref->{trust_level} or confess;    # used if ask_user
    defined($start_pos) or confess;

    my @objects_at_that_location;
    if ( $direction eq $DIR::RIGHT ) {
        @objects_at_that_location =
            grep { $_->get_left_edge() eq $start_pos } ( @elements, values %groups );
    }
    elsif ( $direction eq $DIR::LEFT ) {
        @objects_at_that_location =
            grep { $_->get_right_edge() eq $start_pos } ( @elements, values %groups );
    }

    my $expected_structure_string = $object->get_structure_string();

    my ( @matching_objects, @potentially_matching_objects );
    for (@objects_at_that_location) {
        if ( $_->GetEffectiveObject()->get_structure_string() eq $expected_structure_string ) {
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
            $trust_level *= 0.02;    # had multiplied by 50 for toss...
            if ( $e->WorthAsking($trust_level) ) {
                $e->Ask("<trust: $trust_level> $reason");
            }
        }
        else {
            die $e;
        }
    }

    if ($is_object_literally_present) {
        my $plonk_result = __PlonkIntoPlace( $start_pos, $direction, $object );
        confess "Plonk failed. Shouldn't have." unless $plonk_result->PlonkWasSuccessful();
        my $present_object = $plonk_result->get_resultant_object();
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
                {   actual   => $_,
                    intended => $object,
                }
            )
        );
    }

    return $strength_chooser->( \@matching_objects );
}

sub SErr::AskUser::WorthAsking {
    my ( $self, $trust_level ) = @_;
    ### trust_level: $trust_level
    my ( $match_size, $ask_size )
        = ( scalar( @{ $self->already_matched() } ), scalar( @{ $self->next_elements() } ) );
    my $fraction_already_matched = $match_size / ( $match_size + $ask_size );
    $trust_level += ( 1 - $trust_level ) * $fraction_already_matched;
    ### trust_level: $trust_level
    ### acceptable: $Global::AcceptableTrustLevel
    return 0 if ( $trust_level < $Global::AcceptableTrustLevel );
    return SUtil::toss($trust_level) ? $trust_level : 0;
}

sub SErr::AskUser::Ask {
    my ( $self, $msg ) = @_;
    my $already_matched = $self->already_matched();
    my $next_elements   = $self->next_elements();

    my $object_being_looked_for          = $self->object();
    my $position_it_is_being_looked_from = $self->from_position();
    my $direction_to_look_in             = $self->direction();

    if (@$already_matched) {
        $msg .= "I found the expected terms " . join( ', ', @$already_matched );
    }

    my $answer = main::ask_user_extension( $next_elements, $msg );
    if ($answer) {
        SWorkspace->insert_elements(@$next_elements);
        $Global::AcceptableTrustLevel = 0.5;
        main::update_display();
        $Global::Break_Loop = 1;

        if ( defined $object_being_looked_for ) {
            __PlonkIntoPlace( $position_it_is_being_looked_from,
                              $direction_to_look_in, $object_being_looked_for );
        }

    }
    else {
        my $seq = join( ', ', @$next_elements );
        $Global::ExtensionRejectedByUser{$seq} = 1;
    }
    return $answer;
}

sub SortLeftToRight {
    return ikeysort { $_->get_left_edge() } @_;
}

sub FindDirectionOfObjectSet {
    my (@objects) = @_;

    # Assumption: @objects are live.
    my @left_edges = map { $LeftEdge_of{$_} } @objects;
    my $how_many = scalar(@objects);
    confess "Need at least 2" if $how_many <= 1;

    my ( $leftward, $rightward );
    for ( 0 .. $how_many - 2 ) {
        my $diff = $left_edges[ $_ + 1 ] - $left_edges[$_];
        if ( $diff > 0 ) {
            $rightward++;
        }
        elsif ( $diff < 0 ) {
            $leftward++;
        }
        else {
            return $DIR::UNKNOWN;
        }
    }

    return $DIR::NEITHER if ( $leftward and $rightward );
    return $DIR::LEFT    if $leftward;
    return $DIR::RIGHT   if $rightward;
    confess "huh?";
}

sub DeleteObjectsInconsistentWith {
    my ($ruleapp) = @_;

    for my $rel ( values %relations ) {
        my $is_consistent = $ruleapp->CheckConsitencyOfRelation($rel);
        $rel->uninsert();
    }

    my @groups = values %groups;
    for my $gp (@groups) {
        next unless exists $groups{$gp};
        my $is_consistent = $ruleapp->CheckConsitencyOfGroup($gp);
        SWorkspace->remove_gp($gp) unless $is_consistent;
    }
}

1;

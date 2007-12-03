#####################################################
#
#    Package: SAnchored
#
#####################################################
#   Objects anchored in the workspace.
#####################################################

package SAnchored;
use strict;
use Carp;
use Class::Std;
use English qw(-no_match_vars);
use base qw{SObject};

# use Smart::Comments;

use List::Util qw(min max sum);
use Class::Multimethods;
multimethod 'apply_reln';

my %left_edge_of : ATTR(:get<left_edge> :set<left_edge>);       # Left edge. 0 is leftmost.
my %right_edge_of : ATTR(:get<right_edge> :set<right_edge>);    # Right edge.

use overload fallback => 1;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
}

sub recalculate_edges {
    my ($self) = @_;
    my $id = ident $self;

    my %slots_taken;
    for my $item ( @{ $self->get_parts_ref } ) {
        confess "SAnchored->create called with a non anchored object"
            unless UNIVERSAL::isa( $item, "SAnchored" );
        my ( $left, $right ) = $item->get_edges();
        @slots_taken{ $left .. $right } = ( $left .. $right );
    }

    my @keys = values %slots_taken;
    ## @keys
    my ( $left, $right )
        = List::MoreUtils::minmax( $keys[0], @keys )
        ;    #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    $left_edge_of{$id}  = $left;
    $right_edge_of{$id} = $right;
    ### insist: scalar(@keys) == $right - $left + 1
}

# method: set_edges
# Sets both edges at once
#
sub set_edges {
    my ( $self, $left, $right ) = @_;
    my $id = ident $self;
    unless ( defined $left and defined $right ) {
        confess "SAnchored must have edges defined";
    }
    $left_edge_of{$id}  = $left;
    $right_edge_of{$id} = $right;
    return $self;
}

# method: get_edges
#
#
sub get_edges {
    my ($self) = @_;
    my $id = ident $self;

    return ( $left_edge_of{$id}, $right_edge_of{$id} );
}

sub create {
    my ( $package, @items ) = @_;
    SErr::EmptyCreate->throw() unless @items;
    if ( @items == 1 ) {
        return $items[0] if UNIVERSAL::isa( $items[0], 'SAnchored' );
        confess "Unanchored object!";
    }

    SErr::HolesHere->throw('Holes here') if SWorkspace->are_there_holes_here(@items);

    # I assume @items are live.
    my $direction = SWorkspace::__FindObjectSetDirection(@items);
    return unless $direction->IsLeftOrRight();

    my $object = $package->new(
        {   items      => [@items],
            group_p    => 1,
            left_edge  => -1,           # Will shortly be reset
            right_edge => -1,           # Will shortly be reset
            direction  => $direction,
        }
    );

    $object->recalculate_edges();
    $object->UpdateStrength();
    return $object;
}

# method: get_bounds_string
# returns a string containing the left and right boundaries
#
sub get_bounds_string {
    my ($self) = @_;
    my $id = ident $self;
    return " <$left_edge_of{$id}, $right_edge_of{$id}> ";
}

sub get_span {
    my ($self) = @_;
    my $id = ident $self;
    return $right_edge_of{$id} - $left_edge_of{$id} + 1;
}

sub as_text {
    my ($self)           = @_;
    my $bounds_string    = $self->get_bounds_string();
    my $structure_string = $self->GetAnnotatedStructureString();
    my $metonym_string = $self->get_metonym_activeness() ? '--*-> ' . $self->GetEffectiveObject()->get_structure_string(): '';
    return "SAnchored $bounds_string $structure_string $metonym_string";
}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;
    my ( $l, $r ) = $self->get_edges;

    if ( $verbosity == 0 ) {
        return new SInsertList( "SAnchored", "heading", "[$l, $r] ", "range", "\n" );
    }

    if ( $verbosity == 1 or $verbosity == 2 ) {
        my $list = $self->as_insertlist(0);
        $list->concat( $self->categories_as_insertlist( $verbosity - 1 )->indent(1) );
        $list->append( "Extendibility: ",    'heading' );
        $list->append( "Direction: ",        'heading', $self->get_direction->as_text, "", "\n" );
        $list->append( "Meto activeness: ",  'heading', $self->get_metonym_activeness(), "", "\n" );
        $list->append( "Self:             ", 'heading', $self, '', "\n" );
        $list->append( "Effective object: ", 'heading', $self->GetEffectiveObject(), '', "\n" );
        $list->append( "Flattened: ", 'heading', join( ", ", @{ $self->get_flattened() } ),
            '', "\n" );
        $list->append( "Items: ", 'heading', join( ", ", @{ $self->get_parts_ref } ), '', "\n" );
        $list->append( "Fringe: ", 'heading', "\n" );

        for ( @{ SThought->create($self)->get_fringe } ) {
            my ( $t, $v ) = @$_;
            $list->append("\t$v\t$t\n");
        }

        $list->append( "History: ", 'heading', "\n" );
        for ( @{ $self->get_history } ) {
            $list->append("$_\n");
        }
        return $list;
    }

    confess "Verbosity $verbosity not implemented for " . ref $self;

}

sub get_next_pos_in_dir {
    my ( $self, $direction ) = @_;
    my $id = ident $self;

    if ( $direction eq DIR::RIGHT() ) {
        ## Dir Left
        return $right_edge_of{$id} + 1;
    }
    elsif ( $direction eq DIR::LEFT() ) {
        ## Dir Left
        my $le = $left_edge_of{$id};
        return unless $le > 0;
        return $le - 1;
    }
    else {
        confess "funny direction to extnd in!!";
    }

}

sub spans {
    my ( $self, $other ) = @_;
    my ( $sl,   $sr )    = $self->get_edges;
    my ( $ol,   $or )    = $other->get_edges;
    return ( $sl <= $ol and $or <= $sr );
}

sub overlaps {
    my ( $self, $other ) = @_;
    my ( $sl,   $sr )    = $self->get_edges;
    my ( $ol,   $or )    = $other->get_edges;
    return ( ( $sr <= $or and $sr >= $ol ) or ( $or <= $sr and $or >= $sl ) );
}

sub UpdateStrength {
    my ($self) = @_;
    my $strength_from_parts
        = 20 + 0.2 * ( sum( map { $_->get_strength() } @{ $self->get_parts_ref() } ) || 0 );
    my $strength_from_categories
        = 30 * ( sum( @{ SLTM::GetRealActivationsForConcepts( $self->get_categories() ) } ) || 0 );
    my $strength = $strength_from_parts + $strength_from_categories;
    $strength += $Global::GroupStrengthByConsistency{$self};
    $strength = 100 if $strength > 100;
    ### p, c, t: $strength_from_parts, $strength_from_categories, $strength
    $self->set_strength($strength);
}

sub Extend {
    scalar(@_) == 3 or confess "Need 3 arguments";
    my ( $self, $to_insert, $insert_at_end_p ) = @_;

    # $insert_at_end_p is true if we should insert at end, as opposed to at the beginning.

    my $id        = ident $self;
    my $parts_ref = $self->get_parts_ref();    # It's in SObject...

    my @parts_of_new_group;
    if ($insert_at_end_p) {
        @parts_of_new_group = ( @$parts_ref, $to_insert );
    }
    else {
        @parts_of_new_group = ( $to_insert, @$parts_ref );
    }

    my $potential_new_group = SAnchored->create(@parts_of_new_group)
        or SErr::CouldNotCreateExtendedGroup->new("Extended group creation failed")->throw();
    my $conflicts = SWorkspace::__FindGroupsConflictingWith($potential_new_group);
    if ($conflicts) {
        $conflicts->Resolve( { IgnoreConflictWith => $self } ) or return;
    }

    # If there are supergroups, they must die. Kludge, for now:
    if ( my @supergps = SWorkspace->GetSuperGroups($self) ) {
        if ( SUtil::toss(0.5) ) {
            for (@supergps) {
                SWorkspace::__DeleteGroup($_);
            }
        }
        else {
            return;
        }
    }

    # If we get here, all conflicting incumbents are dead.
    @$parts_ref = @parts_of_new_group;

    $self->Update();
    $self->AddHistory( "Extended to become " . $self->get_bounds_string() );
    return 1;
}

sub Update {
    my ($self) = @_;
    $self->recalculate_edges();
    $self->recalculate_categories();
    $self->recalculate_relations();
    $self->UpdateStrength();
    if ( my $underlying_reln = $self->get_underlying_reln() ) {
        eval { $self->set_underlying_reln( $underlying_reln->get_rule() ) };
        if ($EVAL_ERROR) {
            SWorkspace->remove_gp($self);
        }
    }

    # SWorkspace::UpdateGroupsContaining($self);
    SWorkspace::__UpdateGroup($self);
}

sub FindExtension {
    @_ == 3 or confess "FindExtension for an object requires 3 args";
    my ( $self, $direction_to_extend_in, $skip ) = @_;
    my $direction_of_self = $self->get_direction();
    return unless $direction_of_self->PotentiallyExtendible();

    my $underlying_ruleapp = $self->get_underlying_reln() or return;
    return $underlying_ruleapp->FindExtension( $direction_to_extend_in, { skip => $skip } );
}

sub CheckSquintability {
    my ( $self, $intended ) = @_;
    my $intended_structure_string = $intended->get_structure_string();
    return
        map { $self->CheckSquintabilityForCategory( $intended_structure_string, $_ ) }
        @{ $self->get_categories() };
}

sub CheckSquintabilityForCategory {
    my ( $self, $intended_structure_string, $category ) = @_;
    if ( my $squintability_checker = $category->get_squintability_checker() ) {
        return $squintability_checker->( $self, $intended_structure_string );
    }

    my $bindings = $self->GetBindingForCategory($category)
        or confess "CheckSquintabilityForCategory called on object not an instance of the category";

    my @meto_types = $category->get_meto_types();
    my @return;
    for my $name (@meto_types) {
        my $finder = $category->get_meto_finder($name);
        my $squinted = $finder->( $self, $category, $name, $bindings ) or next;
        next
            unless $squinted->get_starred()->get_structure_string() eq $intended_structure_string;
        push @return, [ $category, $name ];
    }
    return @return;
}

sub IsFlushRight {
    my ($self) = @_;
    $right_edge_of{ ident $self} == $SWorkspace::ElementCount - 1 ? 1 : 0;
}

sub IsFlushLeft {
    my ($self) = @_;
    $left_edge_of{ ident $self} == 0 ? 1 : 0;
}

1;

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
use base qw{SObject};

# use Smart::Comments;

use List::Util qw(min max sum);
use Class::Multimethods;
multimethod 'apply_reln';

my %left_edge_of : ATTR(:get<left_edge> :set<left_edge>)
  ;    # Left edge. 0 is leftmost.
my %right_edge_of : ATTR(:get<right_edge> :set<right_edge>);    # Right edge.
my %right_extendibility_of : ATTR(:set<right_extendibility>)
  ;    # Can we extend right?
my %left_extendibility_of : ATTR(:set<left_extendibility>)
  ;    # Can we extend left?

use overload fallback => 1;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
    $self->set_left_extendibility($EXTENDIBILE::UNKNOWN);
    $self->set_right_extendibility($EXTENDIBILE::UNKNOWN);
}

# method: recalculate_edges
#
#
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
    my ( $left, $right ) =
      List::MoreUtils::minmax( $keys[0], @keys )
      ; #Funny syntax because minmax is buggy, doesn't work for list with 1 element
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

# method: create
# Creates an anchored object
#
#    All of the items should also be anchored.
# A sanity check ensures that there are no "holes". The edges get set automagically.
sub create {
    my ( $package, @items ) = @_;

    my @left_edges;     # for finding direction
    my @right_edges;    # for finding direction
    if ( @items == 1 and UNIVERSAL::isa( $items[0], "SAnchored" ) ) {
        return $items[0];
    }

    SWorkspace->are_there_holes_here(@items)
      and SErr::HolesHere->throw("Holes here!");

    for my $item (@items) {
        my ( $left, $right ) = $item->get_edges();
        push @left_edges,  $left;
        push @right_edges, $right;
    }

    my ( $left, $right ) = ( min(@left_edges), max(@right_edges) );

    # lets find the direction now
    my $direction;
    {
        my ( $leftward, $rightward, $same );
        my $how_many = scalar(@left_edges) - 1;
        for ( 0 .. $how_many - 1 ) {
            my $diff = $left_edges[ $_ + 1 ] - $left_edges[$_];
            if ( $diff > 0 ) {
                $rightward++;
            }
            elsif ( $diff < 0 ) {
                $leftward++;
            }
            else {
                $same++;
                last;
            }
        }
        $direction =
            $same ? $DIR::UNKNOWN
          : ( $leftward  and not $rightward ) ? $DIR::LEFT
          : ( $rightward and not $leftward )  ? $DIR::RIGHT
          :                                     $DIR::NEITHER;
    }

    if ( $direction eq DIR::NEITHER() or $direction eq DIR::UNKNOWN() ) {

        # SErr->throw("Funny object creation attempted");
        return;
    }

    my $object = $package->new(
        {
            items      => [@items],
            group_p    => 1,
            left_edge  => $left,
            right_edge => $right,
            direction  => $direction,
        }
    );

    $object->UpdateStrength();
    return $object;
}

# method: get_bounds_string
# returns a string containing the left and right boundaries
#
sub get_bounds_string {
    my ($self) = @_;
    my $id = ident $self;
    return " [$left_edge_of{$id}, $right_edge_of{$id}] ";
}

sub get_span {
    my ($self) = @_;
    my $id = ident $self;
    return $right_edge_of{$id} - $left_edge_of{$id} + 1;
}

sub as_text {
    my ($self) = @_;
    return "SAnchored " . $self->get_bounds_string();
}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;
    my ( $l, $r ) = $self->get_edges;

    if ( $verbosity == 0 ) {
        return new SInsertList( "SAnchored", "heading", "[$l, $r] ", "range",
            "\n" );
    }

    if ( $verbosity == 1 or $verbosity == 2 ) {
        my $list = $self->as_insertlist(0);
        $list->concat(
            $self->categories_as_insertlist( $verbosity - 1 )->indent(1) );
        $list->append( "Extendibility: ", 'heading' );
        my ( $le, $re ) =
          ( $left_extendibility_of{$id}, $right_extendibility_of{$id} );
        $list->append(
            ( $le ? "$le->{mode}, " : "No, " ),
            "", ( $re ? "$re->{mode}" : "No" ),
            "", "\n"
        );
        $list->append( "Direction: ", 'heading', $self->get_direction->as_text,
            "", "\n" );
        $list->append(
            "Meto activeness: ",
            'heading', $self->get_metonym_activeness(),
            "", "\n"
        );
        $list->append( "Self:             ", 'heading', $self, '', "\n" );
        $list->append(
            "Effective object: ",
            'heading', $self->get_effective_object(),
            '', "\n"
        );
        $list->append( "Flattened: ", 'heading',
            join( ", ", @{ $self->get_flattened() } ),
            '', "\n" );
        $list->append( "Items: ", 'heading',
            join( ", ", @{ $self->get_parts_ref } ),
            '', "\n" );
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

# XXX(Assumption): [2006/10/14] Based on underlying relation, may change with rules.
sub get_right_extendibility {
    my ($self) = @_;
    my $id = ident $self;

    my $rel = $self->get_underlying_reln();

    return EXTENDIBILE::NO() unless $rel;
    return $right_extendibility_of{$id};
}

sub get_left_extendibility {
    my ($self) = @_;
    my $id = ident $self;

    my $rel = $self->get_underlying_reln();

    return EXTENDIBILE::NO() unless $rel;
    return $left_extendibility_of{$id};
}

sub set_underlying_reln : CUMULATIVE {
    my ( $self, $reln ) = @_;
    my $id = ident $self;
    $reln or confess "Cannot set underlying relation to be an undefined value!";

    $right_extendibility_of{$id} = EXTENDIBILE::PERHAPS();
    $left_extendibility_of{$id}  = EXTENDIBILE::PERHAPS();
}

sub get_next_pos_in_dir {
    my ( $self, $direction ) = @_;
    my $id = ident $self;

    if ( $direction eq DIR::RIGHT() ) {
        return $right_edge_of{$id} + 1;
    }
    elsif ( $direction eq DIR::LEFT() ) {
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
    my $strength_from_parts =
      20 + 0.2 * sum( map { $_->get_strength() } @{ $self->get_parts_ref() } );
    my $strength_from_categories =
        30 * sum( @{SLTM::GetRealActivationsForIndices($self->get_categories())});
    my $strength = $strength_from_parts + $strength_from_categories;
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

    my $potential_new_group = SAnchored->create(@parts_of_new_group);
    my ( $exact_conflict, @subset_conflicts ) =
      SWorkspace->FindGroupsConflictingWith($potential_new_group);

    if ($exact_conflict) {
        SWorkspace->FightUntoDeath(
            {
                challenger => $potential_new_group,
                incumbent  => $exact_conflict
            }
        ) or return;
    }

    for my $some_conflict (@subset_conflicts) {

        # Would of course conflict with the unextended $self!
        next if $some_conflict eq $self;

        # Could already have been deleted!
        next unless exists( $SWorkspace::groups{$some_conflict} );

        SWorkspace->FightUntoDeath(
            {
                challenger => $potential_new_group,
                incumbent  => $some_conflict
            }
        ) or return;
    }

    # If we get here, all conflicting incumbents are dead.
    @$parts_ref = @parts_of_new_group;

    $self->recalculate_edges();
    $self->recalculate_categories();
    $self->recalculate_relations();
    $self->UpdateStrength();

    $self->add_history( "Extended to become " . $self->get_bounds_string() );
    return 1;
}

sub FindExtension {
    my ( $self, $direction_to_extend_in ) = @_;
    my $direction_of_self = $self->get_direction();
    return unless $direction_of_self->PotentiallyExtendible();

    my ( $reln, $end_object );
    if ( $direction_of_self eq $direction_to_extend_in ) {
        $reln = $self->get_underlying_reln() or return;
        $end_object = $self->[-1];
    }
    else {
        my $underlying_reln = $self->get_underlying_reln() or return;
        $reln = $underlying_reln->FlippedVersion() or return;
        $end_object = $self->[0];
    }

    my $next_position =
      $end_object->get_next_pos_in_dir($direction_to_extend_in);
    return unless defined $next_position;

    my $expected_next_object =
      apply_reln( $reln, $end_object->get_effective_object() )
      or return;

    return SWorkspace->GetSomethingLike(
        {
            object    => $expected_next_object,
            start     => $next_position,
            direction => $direction_to_extend_in,
            trust_level => 50,
            reason => 'Attempting to extend ' . $self->get_structure_string(),
        }
    );

}

sub CheckSquintability {
    my ( $self, $intended ) = @_;
    my $intended_structure_string = $intended->get_structure_string();
    return map {
        $self->CheckSquintabilityForCategory( $intended_structure_string, $_ )
    } @{$self->get_categories()};
}

sub CheckSquintabilityForCategory {
    my ( $self, $intended_structure_string, $category ) = @_;
    if ( my $squintability_checker = $category->get_squintability_checker() ) {
        return $squintability_checker->( $self, $intended_structure_string );
    }

    my $bindings = $self->get_cat_bindings($category)
      or confess
"CheckSquintabilityForCategory called on object not an instance of the category";

    my @meto_types = $category->get_meto_types();
    my @return;
    for my $name (@meto_types) {
        my $finder = $category->get_meto_finder($name);
        my $squinted = $finder->( $self, $category, $name, $bindings ) or next;
        next
          unless $squinted->get_starred()->get_structure_string() eq
          $intended_structure_string;
        push @return, [ $category, $name ];
    }
    return @return;
}

1;

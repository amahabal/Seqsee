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
#use Smart::Comments;
use List::Util qw(min max);

# variable: %left_edge_of 
#    left edge
my %left_edge_of :ATTR(:get<left_edge> :set<left_edge>);

# variable: %right_edge_of
#    right edge
my %right_edge_of :ATTR(:get<right_edge> :set<right_edge>);


# variable: %right_extendibility_of
#    Could this gp be extended rightward?
#    -1 means No!, 0 means unknown.
my %right_extendibility_of :ATTR(:set<right_extendibility>);


# variable: %left_extendibility_of
#    same as above, leftward?
my %left_extendibility_of :ATTR(:set<left_extendibility>);

use overload fallback => 1;

# method: BUILD
# 
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
}



# method: recalculate_edges
# 
#
sub recalculate_edges{
    my ( $self ) = @_;
    my $id = ident $self;

    my %slots_taken;
    for my $item (@{$self->get_parts_ref}) {
        SErr->throw("SAnchored->create called with a non anchored object") unless UNIVERSAL::isa( $item, "SAnchored");
        my ($left, $right) = $item->get_edges();
        @slots_taken{ $left..$right } = ( $left .. $right );
    }

    my @keys = values %slots_taken;
    ## @keys
    my ($left, $right) = List::MoreUtils::minmax($keys[0], @keys); #Funny syntax because minmax is buggy, doesn't work for list with 1 element    
    $left_edge_of{$id} = $left;
    $right_edge_of{$id} = $right;
}



# method: set_edges
# Sets both edges at once
#
sub set_edges{
    my ( $self, $left, $right ) = @_;
    my $id = ident $self;
    unless (defined $left and defined $right) {
        confess "SAnchored must have edges defined";
    }
    $left_edge_of{$id} = $left;
    $right_edge_of{$id} = $right;
    return $self;
}


# method: get_edges
# 
#
sub get_edges{
    my ( $self ) = @_;
    my $id = ident $self;

    return ( $left_edge_of{$id}, $right_edge_of{$id} );

}




# method: create
# Creates an anchored object
#
#    All of the items should also be anchored. A sanity check ensures that there are no "holes". The edges get set automagically.
sub create{
    my ( $package, @items ) = @_;

    my @left_edges; # for finding direction
    my @right_edges; # for finding direction
    if (@items == 1 and UNIVERSAL::isa($items[0], "SAnchored")) {
        # SErr->throw("A group creation is being attempted based on a single object");
        return $items[0];
    }

    my $holes_here = SWorkspace->are_there_holes_here(@items);
    if ($holes_here) {
        SErr::HolesHere->throw("There are holes here!");
    }

    for my $item (@items) {
        my ($left, $right) = $item->get_edges();
        push @left_edges, $left;
        push @right_edges, $right;
    }

    my ($left, $right) = (min(@left_edges), max(@right_edges));

    # lets find the direction now
    my $direction;
    {
        my ($leftward,$rightward, $same);
        my $how_many = scalar(@left_edges) - 1;
        for (0..$how_many-1) {
            my $diff = $left_edges[$_+1] - $left_edges[$_];
            if ($diff > 0) {
                $rightward++;
            } elsif ($diff < 0) {
                $leftward++;
            } else {
                $same++;
                last;
            }
        }
        if ($same) {
            $direction = DIR::UNKNOWN();
        } elsif ($leftward and not $rightward) {
            $direction = DIR::LEFT();
        } elsif ($rightward and not $leftward) {
            $direction = DIR::RIGHT();
        } else {
            $direction = DIR::NEITHER();
        }
    }

    if ($direction eq DIR::NEITHER() or $direction eq DIR::UNKNOWN()) {
        # SErr->throw("Funny object creation attempted");
        return;
    }
    
    return $package->new( { items => [@items],
                            group_p => 1,
                            left_edge => $left,
                            right_edge => $right,
                            direction  => $direction,
                        });
}



# method: get_bounds_string
# returns a string containing the left and right boundaries
#
sub get_bounds_string{
    my ( $self ) = @_;
    my $id = ident $self;
    return " [$left_edge_of{$id}, $right_edge_of{$id}] ";
}

sub get_span{
    my ( $self ) = @_;
    my $id = ident $self;
    return $right_edge_of{$id} - $left_edge_of{$id} + 1;
}


sub as_text{
    my ( $self ) = @_;
    return "SAnchored ". $self->get_bounds_string();
}

sub as_insertlist{
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;
    my ($l, $r) = $self->get_edges;

    if ($verbosity == 0) {
        return new SInsertList( "SAnchored", "heading", "[$l, $r] ", "range", "\n");
    }

    if ($verbosity == 1 or $verbosity == 2) {
        my $list = $self->as_insertlist(0);
        $list->concat( $self->categories_as_insertlist($verbosity - 1)->indent(1));
        $list->append( "Direction: ", 'heading', $self->get_direction->as_text, "", "\n");
        $list->append( "Fringe: ", 'heading', "\n");
        for (@{ SThought->create($self)->get_fringe}) {
            my ($t, $v) = @$_;
            $list->append("\t$v\t$t\n");
        }

        $list->append( "History: ", 'heading', "\n");
        for (@{$self->get_history}) {
            $list->append("$_\n");
        }
        return $list;
    }


    confess "Verbosity $verbosity not implemented for ". ref $self;

}

sub get_right_extendibility{
    my ( $self ) = @_;
    my $id = ident $self;

    my $rel = $self->get_underlying_reln();
    
    return EXTENDIBILE::NO() unless $rel;
    return $right_extendibility_of{$id};
}

sub get_left_extendibility{
    my ( $self ) = @_;
    my $id = ident $self;

    my $rel = $self->get_underlying_reln();
    
    return EXTENDIBILE::NO() unless $rel;
    return $left_extendibility_of{$id};
}

sub set_underlying_reln :CUMULATIVE{
    my ( $self, $reln ) = @_;
    my $id = ident $self;
    
    $right_extendibility_of{$id} = EXTENDIBILE::PERHAPS();
    $left_extendibility_of{$id}  = EXTENDIBILE::PERHAPS();
}


sub get_next_pos_in_dir{
    my ( $self, $direction ) = @_;
    my $id = ident $self;

    if ($direction eq DIR::RIGHT()) {
        return $right_edge_of{$id} + 1;
    } elsif ($direction eq DIR::LEFT()) {
        my $le = $left_edge_of{$id};
        return unless $le > 0;
        return $le - 1;
    } else {
        confess "funny direction to extnd in!!";
    }

}

sub spans{
    my ( $self, $other ) = @_;
    my ($sl, $sr) = $self->get_edges;
    my ($ol, $or) = $other->get_edges;
    return ($sl <= $ol and $or <= $sr);
}


1;

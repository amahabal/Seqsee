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
use List::MoreUtils qw(minmax);
use Smart::Comments;

# variable: %left_edge_of 
#    left edge
my %left_edge_of :ATTR(:get<left_edge> :set<left_edge>);

# variable: %right_edge_of
#    right edge
my %right_edge_of :ATTR(:get<right_edge> :set<right_edge>);


# variable: %direction_of
#    direction: 1 for right, -1 for left; 0 if neither
#    Based on the left edge
my %direction_of :ATTR( :get<direction> );


# variable: %right_extendibility_of
#    Could this gp be extended rightward?
#    -1 means No!, 0 means unknown.
my %right_extendibility_of :ATTR(:set<right_extendibility>);


# variable: %left_extendibility_of
#    same as above, leftward?
my %left_extendibility_of :ATTR(:set<left_extendibility>);

# method: BUILD
# 
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $direction_of{$id} = $opts_ref->{direction}||0;
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
    ## BuiltObj direction: $direction_of{$id}
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
    my ($left, $right) = minmax($keys[0], @keys); #Funny syntax because minmax is buggy, doesn't work for list with 1 element    
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
    if (@items == 1) {
        SErr->throw("A group creation is being attempted based on a single object");
    }

    my %slots_taken;
    for my $item (@items) {
        SErr->throw("SAnchored->create called with a non anchored object") unless UNIVERSAL::isa( $item, "SAnchored");
        my ($left, $right) = $item->get_edges();
        @slots_taken{ $left..$right } = ( $left .. $right );
        push @left_edges, $left;
    }
    
    my @keys = values %slots_taken;
    ## @keys
    my ($left, $right) = minmax($keys[0], @keys); #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    ## $left, $right
    my $span = $right - $left + 1;
    unless (scalar(@keys) == $span) {
        print "Trying to create SAnchored from @items. @keys are the keys, and the span is $span\n";
        for (@items) {
            print $_->get_bounds_string(), "\n";
        }
        SErr->throw("There are holes here!");
    }
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
            $direction = 0;
        } elsif ($leftward and not $rightward) {
            $direction = -1;
        } elsif ($rightward and not $leftward) {
            $direction = 1;
        } else {
            $direction = 0;
        }
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



# method: could_be_right_extendible
# return true if it is possible that this is right extendible
#
sub could_be_right_extendible{
    my ( $self ) = @_;
    my $id = ident $self;
    return 0 if $right_extendibility_of{$id} == -1;
    return 1;
}

# method: could_be_left_extendible
# return true if it is possible that this is right extendible
#
sub could_be_left_extendible{
    my ( $self ) = @_;
    my $id = ident $self;
    return 0 if $left_extendibility_of{$id} == -1;
    return 1;
}


sub as_text{
    my ( $self ) = @_;
    return "SAnchored ". $self->get_bounds_string();
}


1;

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



# method: BUILD
# 
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    #confess "Need left_edge" 
    #    unless exists $opts_ref->{left_edge};
    #confess "Need right_edge" 
    #    unless exists $opts_ref->{right_edge};

    $left_edge_of{$id}  = $opts_ref->{left_edge};
    $right_edge_of{$id} = $opts_ref->{right_edge};

    # XXX Maybe should inform the workspace or something like that.

}



# method: set_edges
# Sets both edges at once
#
sub set_edges{
    my ( $self, $left, $right ) = @_;
    my $id = ident $self;
    
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
    my %slots_taken;
    for my $item (@items) {
        SErr->throw("SAnchored->create called with a non anchored object") unless UNIVERSAL::isa( $item, "SAnchored");
        my ($left, $right) = $item->get_edges();
        @slots_taken{ $left..$right } = ( $left .. $right );
    }
    
    my @keys = keys %slots_taken;
    ## @keys
    my ($left, $right) = minmax(@keys);
    
    my $span = $right - $left + 1;
    unless (scalar(@keys) == $span) {
        SErr->throw("There are holes here!");
    }
    return $package->new( { items => [@items],
                            group_p => 1,
                            left_edge => $left,
                            right_edge => $right,
                        });
}



1;

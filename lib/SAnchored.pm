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
    $self->set_edges( $opts_ref->{left_edge}, $opts_ref->{right_edge} );
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

    if (@items == 1) {
        SErr->throw("A group creation is being attempted based on a single object");
    }

    my %slots_taken;
    for my $item (@items) {
        SErr->throw("SAnchored->create called with a non anchored object") unless UNIVERSAL::isa( $item, "SAnchored");
        my ($left, $right) = $item->get_edges();
        @slots_taken{ $left..$right } = ( $left .. $right );
    }
    
    my @keys = values %slots_taken;
    ### @keys
    my ($left, $right) = minmax($keys[0], @keys); #Funny syntax because minmax is buggy, doesn't work for list with 1 element
    ### $left, $right
    my $span = $right - $left + 1;
    unless (scalar(@keys) == $span) {
        print "Trying to create SAnchored from @items. @keys are the keys, and the span is $span\n";
        for (@items) {
            print $_->get_bounds_string(), "\n";
        }
        SErr->throw("There are holes here!");
    }
    return $package->new( { items => [@items],
                            group_p => 1,
                            left_edge => $left,
                            right_edge => $right,
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



1;

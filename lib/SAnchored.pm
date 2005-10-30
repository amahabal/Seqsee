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
    confess "Need left_edge" 
        unless exists $opts_ref->{left_edge};
    confess "Need right_edge" 
        unless exists $opts_ref->{right_edge};

    $left_edge_of{$id}  = $opts_ref->{left_edge};
    $right_edge_of{$id} = $opts_ref->{right_edge};

    # XXX Maybe should inform the workspace or something like that.

}

1;

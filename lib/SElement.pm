#####################################################
#
#    Package: SElement
#
#####################################################
#   Manages elements
#    
#   Don't know how this fits in exactly. But the workspace, instead of having raw integers (or SObjects) will have SElements. When they are composed into objects, I may just use their integer core. Hmmmm...
#####################################################

package SElement;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %mag_of :ATTR(:get<mag>);
my %left_edge_of : ATTR( :set<left_edge> :get<left_edge> );
my %right_edge_of : ATTR( :set<right_edge> :get<right_edge> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $mag_of{$id} = $opts->{mag};
    confess "Need mag" unless defined $mag_of{$id};
}



# method: get_structure
# just returns the magnitude
#
sub get_structure{
    my ( $self ) = @_;
    return $mag_of{ident $self};
}



1;

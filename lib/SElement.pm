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
use base qw{SAnchored};
use overload fallback => 1;

my %mag_of :ATTR(:get<mag>);
#my %left_edge_of : ATTR( :set<left_edge> :get<left_edge> );
#my %right_edge_of : ATTR( :set<right_edge> :get<right_edge> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $mag_of{$id} = $opts->{mag};
    confess "Need mag" unless defined $mag_of{$id};
    $mag_of{$id} = int($mag_of{$id});
}



# method: create
# Use this: passes the right argumets along to the constructor
#
sub create{
    my ( $package, $mag, $pos ) = @_;
    return $package->new( {
        items => [$mag],
        group_p => 0,
        mag     => $mag,
        left_edge => $pos,
        right_edge => $pos,
            });
}



# method: get_structure
# just returns the magnitude
#
sub get_structure{
    my ( $self ) = @_;
    return $mag_of{ident $self};
}

sub as_text{
    my ( $self ) = @_;
    my ($l, $r) = $self->get_edges;
    my $mag = $self->get_mag;
    return join("", (ref $self), ":[$l,$r] $mag");
}

sub as_insertlist{
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;
    my ($l, $r) = $self->get_edges;
    my $mag = $self->get_mag;

    if ($verbosity == 0) {
        return new SInsertList( "[$l, $r] ", "range", $mag, "structure", "\n");
    }

    if ($verbosity == 1 or $verbosity == 2) {
        my $list = $self->as_insertlist(0);
        $list->concat( $self->categories_as_insertlist($verbosity - 1)->indent(1));
        return $list;
    }

    die "Verbosity $verbosity not implemented for ". ref $self;

}


1;

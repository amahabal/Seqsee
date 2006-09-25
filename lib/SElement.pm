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

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    confess "Need mag" unless defined $opts->{mag};
    $mag_of{$id} = int($opts->{mag});
}



# method: create
# Use this: passes the right argumets along to the constructor
#
sub create{
    my ( $package, $mag, $pos ) = @_;
    my $obj = $package->new( {
        items => [$mag],
        group_p => 0,
        mag     => $mag,
        left_edge => $pos,
        right_edge => $pos,
            });
    $obj->get_parts_ref()->[0] = $obj; #[sic]
    return $obj;
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

my $POS_FIRST = SPos->new(1);
my $POS_LAST = SPos->new(-1);

sub get_at_position{
    my ( $self, $position ) = @_;
    return $self if ($position eq $POS_FIRST or $position eq $POS_LAST);
    SErr::Pos::OutOfRange->throw("out of range for SElement");
}

sub get_flattened{
    my ( $self ) = @_;
    return [$self->get_mag];
}


1;

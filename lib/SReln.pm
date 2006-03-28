#####################################################
#
#    Package: SReln
#
#####################################################
#####################################################

package SReln;
use strict;
use Carp;
use Class::Std;
use base qw{};



# method: get_ends
# returns the first and the second end
#
sub get_ends{
    my ( $self ) = @_;
    return ($self->get_first(), $self->get_second());
}

sub get_extent{
    my ( $self ) = @_;
    my ( $f, $s ) = $self->get_ends();
    my $l = List::Util::min( $f->get_left_edge(),  $s->get_left_edge() );
    my $r = List::Util::max( $f->get_right_edge(), $s->get_right_edge() );
    return ($l, $r);
}

sub insert{
    my ( $self ) = @_;
    SWorkspace->add_reln($self);
    for ($self->get_ends) {
        $_->add_reln($self);
    }
}

sub get_direction{
    my ( $self ) = @_;
    my ($la, $lb) = map { $_->get_left_edge } $self->get_ends;
    if ($la < $lb) {
        return DIR::RIGHT();
    } elsif ($lb < $la ) {
        return DIR::LEFT();
    } else {
        return DIR::UNKNOWN();
    }
}

sub get_span{
    my ( $self ) = @_;
    my ($la, $ra, $lb, $rb) = map { $_->get_edges() } $self->get_ends;
    return List::Util::max($ra, $rb) - List::Util::min($la, $lb) + 1;
}


1;

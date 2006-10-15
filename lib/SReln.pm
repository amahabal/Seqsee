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
use base qw{SHistory SFasc};

use Class::Std;
my %direction_reln_of : ATTR( :get<direction_reln> :set<direction_reln>  );
# variable: %right_extendibility_of
#    Could this gp be extended rightward?
#    -1 means No!, 0 means unknown.
my %right_extendibility_of :ATTR(:set<right_extendibility> :get<right_extendibility>);


# variable: %left_extendibility_of
#    same as above, leftward?
my %left_extendibility_of :ATTR(:set<left_extendibility> :get<left_extendibility>);

use Class::Multimethods;
multimethod 'find_reln';
use Smart::Comments;

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    my ($f, $s) = ($opts_ref->{first}, $opts_ref->{second});
    if (ref($f) and ref($s)) {
        ## $opts_ref->{first}
        $direction_reln_of{$id} = find_dir_reln( $f->get_direction, $s->get_direction());
    } else {
        $direction_reln_of{$id} = "unknown";
    }
    $right_extendibility_of{$id} = EXTENDIBILE::PERHAPS();
    $left_extendibility_of{$id} = EXTENDIBILE::PERHAPS();
}


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

    my ($f, $s) = $self->get_ends;
    my $reln = $f->get_relation($s);
    $reln->uninsert() if $reln;

    SWorkspace->add_reln($self);
    for ($self->get_ends) {
        $_->add_reln($self);
    }

    $self->UpdateStrength();
}

sub uninsert{
    my ( $self ) = @_;
    SWorkspace->remove_reln($self);
    for ($self->get_ends) {
        $_->remove_reln($self);
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

multimethod find_dir_reln => ('DIR', 'DIR') => sub {
    my ( $da, $db ) = @_;
    if ($da eq DIR::RIGHT()) {
        return ( $db eq DIR::RIGHT()) ? "same" :
            ( $db eq DIR::LEFT()) ? "different" : "unknown";
    } elsif ($da eq DIR::LEFT()) {
        return ( $db eq DIR::RIGHT()) ? "different" :
            ( $db eq DIR::LEFT()) ? "same" : "unknown";
    } else {
        return "unknown";
    }
};

multimethod apply_reln_direction => ('$', 'DIR') => sub {
    my ( $rel_dir, $dir ) = @_;
    if ( $rel_dir eq 'unknown') {
        return DIR::UNKNOWN();
    }
    if ($rel_dir eq 'same') {
        return $dir;
    }
    if ($rel_dir eq 'different') {
        return ($dir eq DIR::RIGHT()) ? DIR::LEFT() :
            ( $dir eq DIR::LEFT()) ? DIR::RIGHT():
                DIR::UNKNOWN();
    }
};



1;

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
use English qw(-no_match_vars);

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
        $direction_reln_of{$id} = find_reln( $f->get_direction, $s->get_direction());
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

    my $add_success = eval { SWorkspace->AddRelation($self) };
    if ($EVAL_ERROR) {
        print $EVAL_ERROR, "\n";
        ### f, s, $reln: $f, $s, $reln
        exit;
    }

    if ($add_success) {
        for ($f, $s) {
            $_->AddRelation($self);
        }
    }

    $self->UpdateStrength();
}

sub uninsert{
    my ( $self ) = @_;
    SWorkspace->RemoveRelation($self);
    for ($self->get_ends) {
        $_->RemoveRelation($self);
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

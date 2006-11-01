#####################################################
#
#    Package: SReln::Position
#
#####################################################
#   Manages relationships between positions
#####################################################

package SReln::Position;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln};

# variable: %text_of
#    keeps words like "succ" or "same"
my %text_of : ATTR( :get<text>);

# multi: find_reln ( SPos::Absolute, SPos::Absolute )
# Relation between two absolute positions.
#
#    For forward absolute, the meaning of succ and pred is clear.
#
#    For backward, the successor of -3 is -4.
#
#    usage:
#
#
#    parameter list:
#
#    return value:
#
#
#    possible exceptions:

multimethod find_reln => qw(SPos::Absolute SPos::Absolute) => sub {
    my ( $pos1, $pos2 ) = @_;
    my $idx1 = $pos1->get_index;
    my $idx2 = $pos2->get_index;
    if ( $idx1 > 0 and $idx2 > 0 ) {
        if ( $idx1 == $idx2 ) {
            return SReln::Position->create( { text => "same" } );
        }
        elsif ( $idx1 + 1 == $idx2 ) {
            return SReln::Position->create( { text => "succ" } );
        }
        elsif ( $idx1 - 1 == $idx2 ) {
            return SReln::Position->create( { text => "pred" } );
        }
        else {
            return;
        }
    }
    elsif ( $idx1 < 0 and $idx2 < 0 ) {
        if ( $idx1 == $idx2 ) {
            return SReln::Position->create( { text => "same" } );
        }
        elsif ( $idx1 - 1 == $idx2 ) {
            return SReln::Position->create( { text => "succ" } );
        }
        elsif ( $idx1 + 1 == $idx2 ) {
            return SReln::Position->create( { text => "pred" } );
        }
        else {
            return;
        }
    }
    else {
        return;
    }
};

{
    my %MEMO;
    sub create{
        my ( $package, $opts_ref ) = @_;
        return $MEMO{$opts_ref->{text}} ||= $package->new($opts_ref);
    }

}

# method: BUILD
# Builds the relation
#
#    Currently sketchy, just stores the "text"

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $text_of{$id} = $opts_ref->{text} or confess "Need text";
}

# multi: apply_reln ( SReln::Position, SPos::Absolute )
# apply position relation to position
#
#
#    usage:
#
#
#    parameter list:
#
#    return value:
#
#
#    possible exceptions:

multimethod apply_reln => qw(SReln::Position SPos::Absolute) => sub {
    my ( $rel, $pos ) = @_;
    my $text = $rel->get_text;
    my $idx  = $pos->get_index;

    if ( $idx > 0 ) {    # Fwd based!
        if ( $text eq "same" ) {
            return $pos;
        }
        elsif ( $text eq "succ" ) {
            return SPos->new( $idx + 1 );
        }
        elsif ( $text eq "pred" ) {
            return unless $idx > 1;
            return SPos->new( $idx - 1 );
        }
        else {
            return;
        }
    }
    else {
        if ( $text eq "same" ) {
            return $pos;
        }
        elsif ( $text eq "succ" ) {
            return SPos->new( $idx - 1 );
        }
        elsif ( $text eq "pred" ) {
            return unless $idx < -1;
            return SPos->new( $idx + 1 );
        }
        else {
            return;
        }
    }

};

# XXX(Board-it-up): [2006/10/14] I am not at all sure this is the right thing to do, but seems
# easiest for now.
multimethod are_relns_compatible => qw(SReln::Position SReln::Position) => sub {
    my ( $r1, $r2 ) = @_;
    return $r1->get_text() eq $r2->get_text();
};

1;

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
use base qw{};

# variable: %text_of
#    keeps words like "succ" or "same"
my %text_of : ATTR( :get<text>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $text_of{$id} = $opts_ref->{text} or confess "Need text";
}

{
    my %MEMO;

    sub create {
        my ( $package, $text ) = @_;
        return $MEMO{$text} ||= $package->new( { text => $text } );
    }

}

my $Successor   = SReln::Position->create('succ');
my $Predecessor = SReln::Position->create('pred');
my $SamePos     = SReln::Position->create('same');

sub get_memory_dependencies { return; }

sub serialize{
    my ( $self ) = @_;
    return $text_of{ident $self};
}

sub deserialize{
    my ( $package, $str ) = @_;
    $package->create($str);
}



my $relation_finder = sub {
    my ( $p1, $p2 ) = @_;
    my $index1 = $p1->get_index();
    my $index2 = $p2->get_index();
    my $diff   = $index2 - $index1;
          $diff == 1  ? return $Successor
        : $diff == -1 ? return $Predecessor
        : $diff == 0  ? return $SamePos
        :               return;
};

sub as_text{
    my ( $self ) = @_;
    return "SReln::Position " . $text_of{ident $self};
}

multimethod find_reln => qw(SPos::Forward SPos::Forward)   => $relation_finder;
multimethod find_reln => qw(SPos::Backward SPos::Backward) => $relation_finder;
multimethod find_reln => qw(SPos SPos)                     => sub {
    return;
};

multimethod apply_reln => qw(SReln::Position SPos::Forward) => sub {
    my ( $rel, $pos ) = @_;
    my $index = $pos->get_index();
          ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Forward' ) )
        : ( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Forward' ) )
        : ( $rel eq $SamePos )     ? return $pos
        :                            return;
};

multimethod apply_reln => qw(SReln::Position SPos::Backward) => sub {
    my ( $rel, $pos ) = @_;
    my $index = $pos->get_index();
          ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Backward' ) )
        : ( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Backward' ) )
        : ( $rel eq $SamePos )     ? return $pos
        :                            return;
};

# XXX(Board-it-up): [2006/10/14] I am not at all sure this is the right thing to do, but seems
# easiest for now.
multimethod are_relns_compatible => qw(SReln::Position SReln::Position) => sub {
    my ( $r1, $r2 ) = @_;
    return $r1 eq $r2;
};

1;

package SRelation;
use strict;
use 5.10.0;
use Class::Std;

my %first_of : ATTR(:name<first>);
my %second_of : ATTR(:name<second>);
my %type_of : ATTR(:name<type>);

my %direction_reln_of : ATTR( :get<direction_reln> :set<direction_reln>  );
my %holeyness_of : ATTR(:get<holeyness>);

use Class::Multimethods;
multimethod 'FindTransform';
use Smart::Comments;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my ( $f, $s ) = ( $opts_ref->{first}, $opts_ref->{second} );
    $direction_reln_of{$id} = FindTransform( $f->get_direction, $s->get_direction() );
    $holeyness_of{$id} = SWorkspace->are_there_holes_here( $f, $s );
}

sub get_ends {
    my ($self) = @_;
    return ( $self->get_first(), $self->get_second() );
}

sub get_extent {
    my ($self) = @_;
    my ( $f, $s ) = $self->get_ends();
    my $l = List::Util::min( $f->get_left_edge(),  $s->get_left_edge() );
    my $r = List::Util::max( $f->get_right_edge(), $s->get_right_edge() );
    return ( $l, $r );
}

sub insert {
    my ($self) = @_;

    my ( $f, $s ) = $self->get_ends;
    my $reln = $f->get_relation($s);
    $reln->uninsert() if $reln;

    my $add_success;
    TRY { $add_success = SWorkspace->AddRelation($self) }
    CATCH {
    DEFAULT: {
            print $err, "\n";
            confess "Relation insertion error";
        }
    }

    if ($add_success) {
        for ( $f, $s ) {
            $_->AddRelation($self);
        }
    }

    $self->UpdateStrength();
}

sub uninsert {
    my ($self) = @_;
    SWorkspace->RemoveRelation($self);
    for ( $self->get_ends ) {
        $_->RemoveRelation($self);
    }
}

sub get_direction {
    my ($self) = @_;
    my ( $la, $lb ) = map { $_->get_left_edge } $self->get_ends;
    if ( $la < $lb ) {
        return DIR::RIGHT();
    }
    elsif ( $lb < $la ) {
        return DIR::LEFT();
    }
    else {
        return DIR::UNKNOWN();
    }
}

sub get_span {
    my ($self) = @_;
    my ( $l, $r ) = $self->get_extent;
    return $r - $l + 1;
}

sub get_pure {
    my ( $self ) = @_;
    return $type_of{ident $self};
}

sub SuggestCategory {
    my ($self) = @_;
    my $id = ident $self;
    if ( $category_of{$id} eq $S::NUMBER ) {
        my $str = $name_of{$id};
        if ( $str eq "same" ) {
            return $S::SAMENESS;
        }
        elsif ( $str eq "succ" ) {
            return $S::ASCENDING;
        }
        elsif ( $str eq "pred" ) {
            return $S::DESCENDING;
        }
    }
}

sub SuggestCategoryForEnds {
    return;
}


1;

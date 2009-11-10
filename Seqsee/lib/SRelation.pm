package SRelation;
use strict;
use 5.10.0;
use Class::Std;
use Carp;
use English qw{-no_match_vars};
use base qw(SHistory SFasc);

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
  $direction_reln_of{$id} =
  FindTransform( $f->get_direction, $s->get_direction() );
  $holeyness_of{$id} = SWorkspace->are_there_holes_here( $f, $s );
}

sub get_ends {
  my ($self) = @_;
  return ( $self->get_first(), $self->get_second() );
}

sub get_extent {
  my ($self) = @_;
  my ( $f, $s ) = $self->get_ends();
  my $l = List::Util::min( $f->get_left_edge(), $s->get_left_edge() );
  my $r = List::Util::max( $f->get_right_edge(), $s->get_right_edge() );
  return ( $l, $r );
}

sub are_ends_contiguous {
  my ($self) = @_;
  my ( $f, $s ) = $self->get_ends();
  my $l = List::Util::max( $f->get_left_edge(), $s->get_left_edge() );
  my $r = List::Util::min( $f->get_right_edge(), $s->get_right_edge() );
  return ( $l == $r + 1 ) ? 1 :0;
}

sub insert {
  my ($self) = @_;

  my ( $f, $s ) = $self->get_ends;
  my $reln = $f->get_relation($s);
  $reln->uninsert() if $reln;

  my $add_success;

  eval { $add_success = SWorkspace->AddRelation($self) };
  if ( my $err = $EVAL_ERROR ) {
    CATCH_BLOCK: {
      print $err, "\n";
      confess "Relation insertion error";
      last CATCH_BLOCK;
      die $err;
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
  my ($self) = @_;
  return $type_of{ ident $self};
}

sub SuggestCategory {
  my ($self)   = @_;
  my $id       = ident $self;
  my $category = $type_of{$id}->get_category();
  if ( $category eq $S::NUMBER ) {
    my $str = $type_of{$id}->get_name();
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
  else {
    return SCat::OfObj::RelationTypeBased->Create( $type_of{$id} );
  }
}

sub SuggestCategoryForEnds {
  return;
}

sub UpdateStrength {
  my ($self) = @_;
  my $strength = 20 * SLTM::GetRealActivationsForOneConcept( $self->get_type );

  # Holeyness penalty
  $strength *= 0.8 if $self->get_holeyness;

  $strength = 100 if $strength > 100;
  $self->set_strength($strength);
}

sub as_text {
  my ($self)          = @_;
  my $id              = ident $self;
  my $first_location  = $first_of{$id}->get_bounds_string();
  my $second_location = $second_of{$id}->get_bounds_string();
  return "$first_location --> $second_location: " . $type_of{$id}->as_text;
}

sub FlippedVersion {
  my ($self) = @_;
  my $id = ident $self;
  my $flipped_type = $type_of{$id}->FlippedVersion() // return;
  return SRelation->new(
    {
      first  => $second_of{$id},
      second => $first_of{$id},
      type   => $flipped_type,
    }
  );
}
1;

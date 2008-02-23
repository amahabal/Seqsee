package Transform::Position;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};

my %text_of : ATTR(:name<text>);

sub create {
    my ( $package, $text ) = @_;
    state %MEMO;
    return $MEMO{$text} ||= $package->new( { text => $text } );
}


my $Successor   = SReln::Position->create('succ');
my $Predecessor = SReln::Position->create('pred');
my $SamePos     = SReln::Position->create('same');
my %ComplexityLookup = ($Successor => 0.9, $Predecessor => 0.9, $SamePos => 1);
my %IsEffectivelyASamenessRelationLookup = ($Successor => 0, $Predecessor => 0, $SamePos => 1);

sub get_memory_dependencies { return; }

sub CalculateComplexityPenalty {
    my ( $self ) = @_;
    return $ComplexityLookup{$self};
}

sub IsEffectivelyASamenessRelation {
    my ( $self ) = @_;
    confess "???" unless exists $IsEffectivelyASamenessRelationLookup{$self};
    return $IsEffectivelyASamenessRelationLookup{$self};
}


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
    return "Transform::Position " . $text_of{ident $self};
}

multimethod FindTransform => qw(SPos::Forward SPos::Forward)   => $relation_finder;
multimethod FindTransform => qw(SPos::Backward SPos::Backward) => $relation_finder;
multimethod FindTransform => qw(SPos SPos)                     => sub {
    return;
};

multimethod ApplyTransform => qw(SReln::Position SPos::Forward) => sub {
    my ( $rel, $pos ) = @_;
    my $index = $pos->get_index();
          ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Forward' ) )
        : ( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Forward' ) )
        : ( $rel eq $SamePos )     ? return $pos
        :                            return;
};

multimethod ApplyTransform => qw(SReln::Position SPos::Backward) => sub {
    my ( $rel, $pos ) = @_;
    my $index = $pos->get_index();
          ( $rel eq $Successor )   ? return ( SPos->new( $index + 1, 'Backward' ) )
        : ( $rel eq $Predecessor ) ? return ( SPos->new( $index - 1, 'Backward' ) )
        : ( $rel eq $SamePos )     ? return $pos
        :                            return;
};


1;



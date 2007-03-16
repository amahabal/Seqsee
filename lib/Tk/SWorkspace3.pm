package Tk::SWorkspace3;
use strict;
use warnings;
use Carp;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);
use base qw/Tk::Derived Tk::Canvas/;

use Themes::Std;

my $Canvas;
my %Id2Obj;
my %Obj2Id;
my ( $Height, $Width );
my $Margin;
my ( $EffectiveHeight, $EffectiveWidth );
my $ElementsYFraction;
my $ElementsY;
my ( $MinGpHeightFraction, $MaxGpHeightFraction );
my ( $MinGpHeight,         $MaxGpHeight );
my $MetoYFraction;
my $MetoY;
my $SpacePerElement;
my $GroupHtPerUnitSpan;
my $RelnZenithFraction;

my %RelationsToHide;
my %AnchorsForRelations;

BEGIN {
    read_config 'config/GUI_ws3.conf' => my %config;
    my %layout_options = %{ $config{Layout} };
    (
        $Margin, $ElementsYFraction, $MinGpHeightFraction, $MaxGpHeightFraction,
        $MetoYFraction, $RelnZenithFraction
      )
      = @layout_options{
        qw{Margin ElementsYFraction MinGpHeightFraction MaxGpHeightFraction
          RelnZenithFraction
          }
      };
}

Construct Tk::Widget 'SWorkspace3';

sub Populate {
    my ( $self, $args ) = @_;
    ( $Canvas, $Height, $Width ) =
      ( $self, $args->{'-height'}, $args->{'-width'} );
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;

    $ElementsY   = $Margin + $EffectiveHeight * $ElementsYFraction;
    $MinGpHeight = $EffectiveHeight * $MinGpHeightFraction;
    $MaxGpHeight = $EffectiveHeight * $MaxGpHeightFraction;
}

sub Update{
    $Canvas->delete('all');
    $GroupHtPerUnitSpan = ($MaxGpHeight - $MinGpHeight) / ($SWorkspace::elements_count || 1);
    $SpacePerElement = $EffectiveWidth / ($SWorkspace::elements_count + 1);
    %AnchorsForRelations = ();
    %RelationsToHide = ();
    DrawGroups();
    DrawElements();
    DrawRelations();
}


sub SElement::draw_ws3 {
    my $self = shift;
    my $idx  = shift;
    ## drawing element: $self
    my $id   = $Canvas->createText(
        @_,
        -text => $self->get_mag(),
        -tags => [ $self, 'element', $idx ],
        Style::Element(),
    );
    return $id;
}

sub SAnchored::draw_ws3 {
    my ($self) = @_;
    my @items  = @$self;
    my @edges  = $self->get_edges();

    my $howmany = scalar(@items);
    for (0..$howmany-2) {
        $RelationsToHide{ $items[$_] . $items[$_+1 ]} = 1;
        $RelationsToHide{ $items[$_+1] . $items[$_]} = 1;
    }

    my $leftx = $Margin + ($edges[0] + 0.1) * $SpacePerElement;
    my $rightx = $Margin + ($edges[1] + 0.9) * $SpacePerElement;
    my $span = $self->get_span();
    my $top = $ElementsY - $MinGpHeight - $span * $GroupHtPerUnitSpan;
    my $bottom = $ElementsY + $MinGpHeight + $span * $GroupHtPerUnitSpan;
    
    if ($self->get_metonym_activeness()) {
        DrawMetonym({ actual_string => $self->get_structure_string(),
                      starred => $self->GetEffectiveObject()->get_structure_string(),
                      x1 => $leftx,
                      x2 => $rightx,
                  });
    }
    $AnchorsForRelations{$self} = [($leftx + $rightx) / 2, $top];
    return $Canvas->createOval($leftx, $top, $rightx, $bottom,
                               Style::Group(),
                                   );

}

sub SReln::draw_ws3 {
    my ($self) = @_;
    my @ends = $self->get_ends();
    return if $RelationsToHide{ join( '', @ends ) };
    my ( $x1, $y1 ) = @{ $AnchorsForRelations{ $ends[0] } || [] };
    my ( $x2, $y2 ) = @{ $AnchorsForRelations{ $ends[1] } || [] };
    my $strength = $self->get_strength();
    return unless ( $x1 and $x2 );
    ## drawing a relation: $x1, $y1, $x2, $y2
    return $Canvas->createLine(
        $x1, $y1,
        ( $x1 + $x2 ) / 2,
        $Margin + $RelnZenithFraction * $EffectiveHeight,
        $x2, $y2,
        Style::Relation($strength),
    );
}

sub DrawItemOnCanvas{
    my $obj = shift;
    my $id = $obj->draw_ws3(@_);
    $Id2Obj{$id} = $obj;
    return $id;
}


sub DrawElements{
    my $counter = 0;
    for my $elt (@SWorkspace::elements) {
        DrawItemOnCanvas( $elt, $counter, $Margin + (0.5 + $counter) * $SpacePerElement, $ElementsY);
        $counter++;
    }
}

sub DrawGroups{
    for my $gp (rikeysort { $_->get_span() } values %SWorkspace::groups) {
        $gp->draw_ws3();
    }
    for my $elt (@SWorkspace::elements) {
        SAnchored::draw_ws3($elt);
    }    
}

sub DrawRelations{
    for my $rel (values %SWorkspace::relations) {
        $rel->draw_ws3();
    }    
}

sub DrawMetonym{
    my ( $opts_ref ) = @_;
    $Canvas->createText(($opts_ref->{x1} + $opts_ref->{x2})/2,
                        $Margin + $MetoY + 20,
                        Style::Element(),
                        -text => $opts_ref->{actual_string},
                            );
    $Canvas->createText(($opts_ref->{x1} + $opts_ref->{x2})/2,
                        $Margin + $MetoY,
                        Style::Element(),
                        -text => $opts_ref->{starred},
                            );
    
}


1;



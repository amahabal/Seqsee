#####################################################
#
#    Package: SGUI::Workspace
#
#####################################################
#####################################################

package SGUI::Workspace;
use strict;
use Carp;
use Class::Std;
use Config::Std;
use base qw{};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);

my %Id2Obj;
my %Obj2Id;
my $Canvas;
my ( $Height, $Width );
my $XOffset;
my $YOffset;
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
          MetoYFraction RelnZenithFraction
          }
      };
}

sub Setup {
    my $package = shift;
    ( $Canvas, $XOffset, $YOffset, $Width, $Height ) = @_;
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;

    $ElementsY   = $YOffset + $Margin + $EffectiveHeight * $ElementsYFraction;
    $MinGpHeight = $EffectiveHeight * $MinGpHeightFraction;
    $MaxGpHeight = $EffectiveHeight * $MaxGpHeightFraction;
    $MetoY       = $YOffset + $Margin +$EffectiveHeight * $MetoYFraction;
}

sub DrawIt {
    DrawLegend( 10, 10 );
    $GroupHtPerUnitSpan =
      ( $MaxGpHeight - $MinGpHeight ) / ( $SWorkspace::ElementCount || 1 );
    $SpacePerElement = $EffectiveWidth / ( $SWorkspace::ElementCount + 1 );
    %AnchorsForRelations = ();
    %RelationsToHide     = ();
    DrawGroups();
    DrawElements();
    DrawRelations();
    DrawLastRunnable();
}

sub SElement::draw_ws3 {
    my $self = shift;
    my $idx  = shift;
    ## drawing element: $self
    my $is_hilit = $Global::Hilit{$self} || 0;
    my $id = $Canvas->createText(
        @_,
        -text => $self->get_mag(),
        -tags => [ $self, 'element', $idx ],
        Style::Element($is_hilit),
    );
    $Canvas->createText($_[0]+5, $_[1]+10, -text => $idx);
    $AnchorsForRelations{$self} ||= [ $_[0], $_[1] - 10 ];
    return $id;
}

sub SAnchored::draw_ws3 {
    my ($self, $is_largest) = @_;
    my @items  = @$self;
    my @edges  = $self->get_edges();
    $is_largest ||= 0;

    my $howmany = scalar(@items);
    for ( 0 .. $howmany - 2 ) {
        $RelationsToHide{ $items[$_] . $items[ $_ + 1 ] } = 1;
        $RelationsToHide{ $items[ $_ + 1 ] . $items[$_] } = 1;
    }

    my $leftx  = $XOffset+$Margin + ( $edges[0] + 0.1 ) * $SpacePerElement;
    my $rightx = $XOffset +$Margin + ( $edges[1] + 0.9 ) * $SpacePerElement;
    my $span   = $self->get_span();
    my $top    = $ElementsY - $MinGpHeight - $span * $GroupHtPerUnitSpan;
    my $bottom = $ElementsY + $MinGpHeight + $span * $GroupHtPerUnitSpan;

    my $is_meto;
    if ( $is_meto = $self->get_metonym_activeness() ) {
        DrawMetonym(
            {
                actual_string => $self->get_structure_string(),
                starred => $self->GetEffectiveObject()->get_structure_string(),
                x1      => $leftx,
                x2      => $rightx,
            }
        );
    }
    $AnchorsForRelations{$self} = [ ( $leftx + $rightx ) / 2, $top ];
    my $strength = $self->get_strength();
    my $is_hilit = $Global::Hilit{$self} || 0;
    my $tags = $is_hilit ? ['hilit'] : [];
    my $canvas_obj = $Canvas->createOval( $leftx, $top, $rightx, $bottom,
        Style::Group( $is_meto, $is_hilit, $strength, $is_largest ),
    );

    $Canvas->createOval($leftx, $top, $rightx, $bottom,
                        Style::GroupBorder( $is_meto, $is_hilit, $strength ),
                        -tags => $tags,
                            );
    return $canvas_obj;
}

sub SReln::draw_ws3 {
    my ($self) = @_;
    my @ends = $self->get_ends();
    return if ($RelationsToHide{ join( '', @ends ) } and not($Global::Hilit{$self}));
    my $is_hilit = $Global::Hilit{$self} || 0;
    my ( $x1, $y1 ) = @{ $AnchorsForRelations{ $ends[0] } || [] };
    my ( $x2, $y2 ) = @{ $AnchorsForRelations{ $ends[1] } || [] };
    my $strength = $self->get_strength();
    return unless ( $x1 and $x2 );
    ## drawing a relation: $x1, $y1, $x2, $y2
    ## $RelnZenithFraction, $EffectiveHeight: $RelnZenithFraction, $EffectiveHeight
    return $Canvas->createLine(
        $x1, $y1,
        ( $x1 + $x2 ) / 2,
        $YOffset +$Margin + $RelnZenithFraction * $EffectiveHeight,
        $x2, $y2, Style::Relation($strength, $is_hilit),
    );
}

sub DrawItemOnCanvas {
    my $obj = shift;
    my $id  = $obj->draw_ws3(@_);
    $Id2Obj{$id} = $obj;
    return $id;
}

sub DrawElements {
    my $counter = 0;
    for my $elt (SWorkspace->GetElements()) {
        DrawItemOnCanvas( $elt, $counter,
            $Margin + ( 0.5 + $counter ) * $SpacePerElement, $ElementsY );
        $counter++;
    }
}

sub DrawGroups {
    my @groups = SWorkspace->GetGroups() or return;
    my $largest_group = shift(@groups);
    $largest_group->draw_ws3(1); # Argument is: $is_largest

    for my $gp (@groups) {
        $gp->draw_ws3();
    }
    for my $elt (SWorkspace::GetElements()) {
        SAnchored::draw_ws3($elt) if ($elt->get_group_p() or $elt->get_metonym_activeness());
    }
    $Canvas->raise('hilit')
}

sub DrawRelations {
    for my $rel ( values %SWorkspace::relations ) {
        $rel->draw_ws3();
    }
}

sub DrawMetonym {
    my ($opts_ref) = @_;
    my $id = $Canvas->createText(
        ( $opts_ref->{x1} + $opts_ref->{x2} ) / 2,
        $MetoY + 20,
        Style::Element(0), -text => $opts_ref->{actual_string},
    );
    my @bbox = $Canvas->bbox($id);
    $Canvas->createLine( @bbox, );
    $Canvas->createLine( @bbox[ 2, 1, 0, 3 ], );
    $Canvas->createText(
        ( $opts_ref->{x1} + $opts_ref->{x2} ) / 2,
        $MetoY,
        Style::Starred(), -text => $opts_ref->{starred},
    );

}

{
    my @grp_str =
      map { my %f = Style::Group( 0, 0, $_ * 10,0 ); $f{-fill} } 0 .. 10;
    my @star_str =
      map { my %f = Style::Group( 1, 0, $_ * 10,0 ); $f{-fill} } 0 .. 10;
    my @reln_str =
      map { my %f = Style::Relation( $_ * 10, 0 ); $f{-fill} } 0 .. 10;

    sub DrawLegend {
        my ( $x, $y ) = @_;
        my $step = 15;
        $Canvas->createText( $x, $y, -text => 'Legend', -anchor => 'nw' );
        my $id1 = $Canvas->createText(
            $x, $y + $step,
            -text   => 'Group Strengths',
            -anchor => 'nw'
        );
        my $id2 = $Canvas->createText(
            $x, $y + 2 * $step,
            -text   => 'Squinting Strengths',
            -anchor => 'nw'
        );
        my $id3 = $Canvas->createText(
            $x, $y + 3 * $step,
            -text   => 'Relation Strengths',
            -anchor => 'nw'
        );
        my $newx = ( $Canvas->bbox( $id1, $id2, $id3 ) )[2] + 10;
        my $box_size = 10;

        for ( 0 .. 10 ) {
            $Canvas->createRectangle(
                $newx + $_ * $box_size, $y + $step,
                $newx + $box_size + $_ * $box_size, $y + $step + $box_size,
                -fill  => $grp_str[$_],
                -width => 0
            );
            $Canvas->createRectangle(
                $newx + $_ * $box_size, $y + 2 * $step,
                $newx + $box_size + $_ * $box_size, $y + 2 * $step + $box_size,
                -fill  => $star_str[$_],
                -width => 0
            );
            $Canvas->createRectangle(
                $newx + $_ * $box_size, $y + 3 * $step,
                $newx + $box_size + $_ * $box_size, $y + 3 * $step + $box_size,
                -fill  => $reln_str[$_],
                -width => 0
            );
        }
    }
}

sub DrawLastRunnable {
    $Canvas->createText(
        $Margin, $Height - $Margin,
        -anchor => 'sw',
        -text   => $Global::CurrentRunnableString
    );
}

1;

#####################################################
#
#    Package: SGUI::Categories
#
#####################################################
#####################################################

package SGUI::Categories;
use strict;
use Carp;
use Class::Std;
use Config::Std;
use Sort::Key qw(rikeysort);
use base qw{};

my $Canvas;
my ( $Height,  $Width );
my ( $XOffset, $YOffset );

my $Margin;
my $EffectiveHeight;
my $EffectiveWidth;

my $ColumnCount;
my $EntriesPerColumn;
my $ColumnWidth;
my $RowHeight;
my $WidthForImage;
my $HeightForImage;

my $SpacePerElement;
my $ElementsY;
my ( $MinGpHeightFraction, $MaxGpHeightFraction );
my ( $MinGpHeight,         $MaxGpHeight );
my $GroupHtPerUnitSpan;

BEGIN {
    read_config 'config/GUI_ws3.conf' => my %config;
    $Margin = $config{Layout}{Margin};

    my %CatLayoutOptions = %{ $config{CategoriesLayout} };
    (
        $EntriesPerColumn,    $ColumnCount,
        $MinGpHeightFraction, $MaxGpHeightFraction
      )
      = @CatLayoutOptions{
        qw{EntriesPerColumn ColumnCount MinGpHeightFraction MaxGpHeightFraction}
      };
}

sub Setup {
    my $package = shift;
    ( $Canvas, $XOffset, $YOffset, $Width, $Height ) = @_;
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;
    $ColumnWidth     = int( $EffectiveWidth / $ColumnCount );
    $RowHeight       = int( $EffectiveHeight / $EntriesPerColumn );
    $WidthForImage   = $ColumnWidth / 2;
    $HeightForImage  = $RowHeight * 0.8;

    $MinGpHeight = $RowHeight * $MinGpHeightFraction;
    $MaxGpHeight = $RowHeight * $MaxGpHeightFraction;
}

sub DrawIt {
    my ( $row, $col ) = ( -1, 0 );
    # print("Max: $MaxGpHeight $MinGpHeight");
    $GroupHtPerUnitSpan =
      ( $MaxGpHeight - $MinGpHeight ) / ( $SWorkspace::ElementCount || 1 );
    $SpacePerElement = $WidthForImage / ( $SWorkspace::ElementCount + 1 );

    my @sorted_objects =
      rikeysort { $_->get_span() } SWorkspace::GetGroups();
    push @sorted_objects, SWorkspace::GetElements();
    my %Cat2Objects;
    for my $obj (@sorted_objects) {
        my $edges_ref = [ $obj->get_edges() ];
        for my $cat ( @{ $obj->get_categories() } ) {
            push @{ $Cat2Objects{$cat} }, $edges_ref;
        }
    }

    for ( keys %Cat2Objects ) {
        my $cat = $S::Str2Cat{$_};
        if ( $row >= $EntriesPerColumn ) {
            $row = 0;
            $col++;
        }
        DrawCategory(
            $cat,
            $XOffset + $Margin + $col * $ColumnWidth,
            $YOffset + $Margin + $row * $RowHeight,
            $Cat2Objects{$_}
        );
        $row++;
    }
}

sub DrawCategory {
    my ( $cat, $left, $top, $objects ) = @_;
    $Canvas->createText(
        $left + $WidthForImage + 5,
        $top + 0.5 * $HeightForImage,
        -anchor => 'w',
        -text   => $cat->get_name()
    );
    $Canvas->createRectangle(
        $left, $top,
        $left + $WidthForImage,
        $top + $HeightForImage,
        -fill => '#EEEEEE'
    );

    # Draw ovals for instances
    my $CenterY = $top + $HeightForImage / 2;
    for my $o (@$objects) {
        my ( $l, $r ) = @$o;
        my $span = $r - $l + 1;
        my ( $oval_left, $oval_right ) =
          ( $left + $SpacePerElement * ($l + 0.8),
            $left + $SpacePerElement * ($r + 1.2) );
        #main::message("GroupHtPerUnitSpan: $GroupHtPerUnitSpan");
        my ( $oval_top, $oval_bottom ) = (
            $CenterY - $MinGpHeight - $span * $GroupHtPerUnitSpan,
            $CenterY + $MinGpHeight + $span * $GroupHtPerUnitSpan
        );
        $Canvas->createOval($oval_left, $oval_top, $oval_right, $oval_bottom,
                            -fill => '#0000FF');
    }

    # Draw ovals for elements
    my ( $oval_top, $oval_bottom ) =
      ( $CenterY - 1, $CenterY + 1 );
    my ( $oval_left, $oval_right ) =
      ( $left + $SpacePerElement - 1, $left + $SpacePerElement + 1 );
    for ( 1 .. $SWorkspace::ElementCount ) {
        $Canvas->createRectangle( $oval_left, $oval_top, $oval_right, $oval_bottom );
        $oval_left  += $SpacePerElement;
        $oval_right += $SpacePerElement;
    }
}

1;

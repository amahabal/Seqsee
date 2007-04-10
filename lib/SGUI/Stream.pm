#####################################################
#
#    Package: SGUI::Stream
#
#####################################################
#####################################################

package SGUI::Stream;
use strict;
use Carp;
use Class::Std;
use Config::Std;
use base qw{};

my $Canvas;
my ( $Height,  $Width );
my ( $XOffset, $YOffset );

my $Margin;
my $EffectiveHeight;
my $EffectiveWidth;
my $EntriesPerColumn;
my $ColumnCount;
my ($ColumnWidth, $RowHeight);

BEGIN {
    read_config 'config/GUI_ws3.conf' => my %config;
    $Margin = $config{Layout}{Margin};

    my %StreamLayoutOptions = %{ $config{StreamLayout} };
    ( $EntriesPerColumn, $ColumnCount ) =
      @StreamLayoutOptions{qw{EntriesPerColumn ColumnCount}};
}

sub Setup {
    my $package = shift;
    ( $Canvas, $XOffset, $YOffset, $Width, $Height ) = @_;
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;
    $ColumnWidth     = int( $EffectiveWidth / $ColumnCount );
    $RowHeight       = int( $EffectiveHeight / $EntriesPerColumn );

}

sub DrawIt{
    DrawThought (
        $SStream::CurrentThought,
        $XOffset+$Margin/2, $YOffset,
        1, # i.e., is current tht
            ) if $SStream::CurrentThought;
    my ( $row, $col ) = ( 0, 0 );
    for my $tht (@SStream::OlderThoughts) {
        next unless $tht;
        $row++;
        if ( $row >= $EntriesPerColumn ) {
            $row = 0;
            $col++;
        }
        DrawThought(
            $tht,
            $XOffset + $Margin + $col * $ColumnWidth,
            $YOffset + $Margin + $row * $RowHeight,
            0, # not current tht
        );
    }
}

sub DrawThought{
    my ( $tht, $left, $top, $is_current ) = @_;
    my $hit_intensity = $SStream::thought_hit_intensity{$tht};
    $Canvas->createRectangle($left, $top, $left + $ColumnWidth, $top + $RowHeight,
                             Style::ThoughtBox($hit_intensity, $is_current),
                                 );
    $Canvas->createText($left+1, $top+1, -anchor => 'nw', -text => $tht->as_text(),
                        Style::ThoughtHead(),
                            );
    my $fringe = $tht->get_stored_fringe();
    my $count = 0;
    for (@$fringe) {
        my ($component, $activation) = @$_;
        $count++;
        $Canvas->createText($left + 10, $top + 15 * $count,
                                -text => $component,
                                -anchor => 'nw',
                            Style::ThoughtComponent($activation, 
                                                    $SStream::hit_intensity{$component},
                                                        ),
                                );
    }
}
1;

#####################################################
#
#    Package: SGUI::Slipnet
#
#####################################################
#####################################################

package SGUI::Slipnet;
use strict;
use Carp;
use Class::Std;
use Config::Std;
use base qw{};

my $Canvas;
my ($Height, $Width);
my ($XOffset, $YOffset);

my $Margin;
my $EffectiveHeight;
my $EffectiveWidth;

# Slipnet display related variables
my $NetEntriesPerColumn;
my $NetColumnCount;
my $NetMaxOvalRadius;
my $NetMaxTextWidth;
my $NetColumnWidth;
my $NetRowHeight;


BEGIN {
    read_config 'config/GUI_ws3.conf' => my %config;
    $Margin = $config{Layout}{Margin};
    my $NetLayoutOptions    = $config{NetLayout};
    $NetEntriesPerColumn = $NetLayoutOptions->{'EntriesPerColumn'};
    $NetColumnCount      = $NetLayoutOptions->{'ColumnCount'};
    $NetMaxOvalRadius      = $NetLayoutOptions->{'MaxOvalRadius'};
    $NetMaxTextWidth     = $NetLayoutOptions->{'MaxTextWidth'};
}

sub Setup {
    my $package = shift;
    ( $Canvas, $XOffset, $YOffset, $Width, $Height ) = @_;
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;
    $NetColumnWidth = int( $EffectiveWidth / $NetColumnCount );
    $NetRowHeight   = int( $EffectiveHeight / $NetEntriesPerColumn );
}

sub DrawIt {
    my @concepts_with_activation = SLTM::GetTopConcepts(10);
    my ( $row, $col ) = ( -1, 0 );
    for (@concepts_with_activation) {
        next unless $_->[1] > 0.05;
        $row++;
        if ( $row >= $NetEntriesPerColumn ) {
            $row = 0;
            $col++;
        }
        NetDrawNode(
            $_,
            $XOffset + $Margin + $col * $NetColumnWidth,
            $YOffset + $Margin + $row * $NetRowHeight
        );

    }
}

sub NetDrawNode {
    my ( $con_ref, $left, $top ) = @_;
    my ( $concept, $activation, $raw_activation, $raw_significance ) =
      @{$con_ref};
    my $radius = $activation* $NetMaxOvalRadius;
    #main::message("Rad: $radius");
    $Canvas->createOval(
        $left + 2 + $NetMaxOvalRadius - $radius,
        $top + 2 + $NetMaxOvalRadius - $radius,
        $left + 2 + $NetMaxOvalRadius + $radius,
        $top + 2 + $NetMaxOvalRadius + $radius,
        Style::NetActivation()
    );
    $Canvas->createText(
        $left + 6 + 2 * $NetMaxOvalRadius,
        $top + 2 + $NetMaxOvalRadius,
        -anchor => 'w',
        -text => $concept->as_text()
    );
}

1;

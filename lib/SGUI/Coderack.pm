package SGUI::Coderack;
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
my ( $MaxRows, $RowHeight );
my ( $NameOffset, $CountOffset, $UrgencyOffset, $HistoricalFractionOffset );

BEGIN {
    read_config 'config/GUI_ws3.conf' => my %config;
    $Margin = $config{Layout}{Margin};

    my %CoderackOptions = %{ $config{CoderackLayout} };
    ( $MaxRows, $NameOffset, $CountOffset, $UrgencyOffset, $HistoricalFractionOffset )
        = @CoderackOptions{ 'MaxRows', 'NameOffset', 'CountOffset', 'UrgencyOffset',
        'HistoricalFractionOffset' };
}

sub Setup {
    my $package = shift;
    ( $Canvas, $XOffset, $YOffset, $Width, $Height ) = @_;
    $EffectiveHeight = $Height - 2 * $Margin;
    $EffectiveWidth  = $Width - 2 * $Margin;
    $RowHeight       = int( $EffectiveHeight / $MaxRows );
}

sub DrawIt {
    my %count;
    my %sum;

    # my %urgencies;
    for my $cl (@SCoderack::CODELETS) {
        my $family  = $cl->[0];
        my $urgency = $cl->[1];
        $family = "SCF::$family";
        $count{$family}++;
        $sum{$family} += $urgency;

        # push @{ $urgencies{$family} }, $urgency;
    }

    if ( my $usum = $SCoderack::URGENCIES_SUM ) {
        for ( values %sum ) {
            $_ /= $usum * 0.01;
        }
    }
    else {
        for ( values %sum ) {
            $_ = '---';
        }
    }

    my $total_run_so_far = List::Util::sum( values %SCoderack::HistoryOfRunnable );
    my $rows_displayed   = 0;
    my $base_x_offset    = $XOffset + $Margin;

    $Canvas->createText(
        $base_x_offset + $NameOffset, $YOffset - 10,
        -anchor => 'nw',
        -text   => "NAME",
    );
    $Canvas->createText(
        $base_x_offset + $CountOffset, $YOffset - 10,
        -anchor => 'nw',
        -text   => "CURR. COUNT",
    );
    $Canvas->createText(
        $base_x_offset + $UrgencyOffset, $YOffset - 10,
        -anchor => 'nw',
        -text   => "Urgeny %",
    );
    $Canvas->createText(
        $base_x_offset + $HistoricalFractionOffset, $YOffset - 10,
        -anchor => 'nw',
        -text   => "% OF ALL RUN",
    );

    while ( my ( $family, $historical_count ) = each %SCoderack::HistoryOfRunnable ) {
        last if $rows_displayed > $MaxRows;
        my $y_pos = $YOffset + $Margin + $rows_displayed * $RowHeight;
        $Canvas->createText(
            $base_x_offset + $NameOffset, $y_pos,
            -text   => $family,
            -anchor => 'nw',
        );
        $Canvas->createText(
            $base_x_offset + $CountOffset, $y_pos,
            -text   => $count{$family},
            -anchor => 'nw'
        );
        $Canvas->createRectangle(
            $base_x_offset + $UrgencyOffset,
            $y_pos,
            $base_x_offset + $UrgencyOffset + $sum{$family},
            $y_pos + 0.8 * $RowHeight,
            -fill => '#0000FF',
        );
        $Canvas->createRectangle(
            $base_x_offset + $UrgencyOffset,
            $y_pos,
            $base_x_offset + $UrgencyOffset + 100,
            $y_pos + 0.8 * $RowHeight,
        );

        $Canvas->createRectangle(
            $base_x_offset + $HistoricalFractionOffset,
            $y_pos,
            $base_x_offset + $HistoricalFractionOffset + 100 * $historical_count
                / $total_run_so_far,
            $y_pos + 0.8 * $RowHeight,
            -fill => '#FF0000',
        );
        $Canvas->createRectangle(
            $base_x_offset + $HistoricalFractionOffset,
            $y_pos,
            $base_x_offset + $HistoricalFractionOffset + 100,
            $y_pos + 0.8 * $RowHeight,
        );

        unless ($rows_displayed % 2) {
            my $y = $YOffset + (2 + $rows_displayed) * $RowHeight - 3;
            #$Canvas->createLine($base_x_offset, $y,
            #                    $base_x_offset + $EffectiveWidth, $y,
            #                        );
            unless ($rows_displayed % 4) {
                my $y2 = $YOffset + (4 + $rows_displayed) * $RowHeight - 3;
                my $id = $Canvas->createRectangle($base_x_offset, $y,
                                                  $base_x_offset + $EffectiveWidth, $y2,
                                                  -fill => '#CCFFDD',
                                                  -outline => '',
                                                      );
                $Canvas->lower($id);
            }
        }
        $rows_displayed++;
    }
}

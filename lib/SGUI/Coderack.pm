SeqseeDisplay Coderack is {
ConfigNames: { MaxRows MaxColumns NameOffset CountOffset UrgencyOffset
                   HistoricalFractionOffset}
Variables: { RowHeight ColumnWidth }
Setup: {
        $RowHeight   = int( $EffectiveHeight / $MaxRows );
        $ColumnWidth = int( $EffectiveWidth / $MaxColumns );
    }
DrawIt: {
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

        for my $column_number ( 0 .. $MaxColumns - 1 ) {
            my $base_x_offset = $XOffset + $Margin + $column_number * $ColumnWidth;
            $Canvas->createText(
                $base_x_offset + $NameOffset, $YOffset - 10,
                -anchor => 'nw',
                -text   => "NAME",
            );
            $Canvas->createText(
                $base_x_offset + $CountOffset, $YOffset - 10,
                -anchor => 'nw',
                -text   => "#",
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
        }

        for ( keys %count ) {
            $SCoderack::HistoryOfRunnable{$_} ||= 0;
        }
        my $current_column = 0;
        my $rows_displayed = 0;
        my $base_x_offset  = $XOffset + $Margin;

        while ( my ( $family, $historical_count ) = each %SCoderack::HistoryOfRunnable ) {
            if ( $rows_displayed > $MaxRows ) {
                $rows_displayed = 0;
                $current_column++;
                $base_x_offset += $ColumnWidth;
            }

            last if $current_column > $MaxColumns;
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
                $base_x_offset + $UrgencyOffset + $sum{$family} * 0.5,
                $y_pos + 0.8 * $RowHeight,
                -fill => '#0000FF',
            );
            $Canvas->createRectangle(
                $base_x_offset + $UrgencyOffset + 49,
                $y_pos,
                $base_x_offset + $UrgencyOffset + 50,
                $y_pos + 0.8 * $RowHeight,
            );

            $Canvas->createRectangle(
                $base_x_offset + $HistoricalFractionOffset,
                $y_pos,
                $base_x_offset + $HistoricalFractionOffset + 50 * $historical_count
                    / $total_run_so_far,
                $y_pos + 0.8 * $RowHeight,
                -fill => '#FF0000',
            ) if $total_run_so_far;
            $Canvas->createText(
                $base_x_offset + $HistoricalFractionOffset + 60,
                $y_pos,
                -text   => $historical_count,
                -anchor => 'nw'
            );
            $Canvas->createRectangle(
                $base_x_offset + $HistoricalFractionOffset + 49,
                $y_pos,
                $base_x_offset + $HistoricalFractionOffset + 50,
                $y_pos + 0.8 * $RowHeight,
            );

            unless ( $rows_displayed % 2 ) {
                my $y = $YOffset + ( 2 + $rows_displayed ) * $RowHeight - 3;

                #$Canvas->createLine($base_x_offset, $y,
                #                    $base_x_offset + $EffectiveWidth, $y,
                #                        );
                unless ( $rows_displayed % 4 ) {
                    my $y2 = $YOffset + ( 4 + $rows_displayed ) * $RowHeight - 3;
                    my $id = $Canvas->createRectangle(
                        $base_x_offset,                $y,
                        $base_x_offset + $ColumnWidth, $y2,
                        -fill    => '#CCFFDD',
                        -outline => '',
                    );
                    $Canvas->lower($id);
                }
            }
            $rows_displayed++;
        }
    }
}
1;

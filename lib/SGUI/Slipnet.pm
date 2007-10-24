SeqseeDisplay Slipnet is {
ConfigNames: {
        EntriesPerColumn ColumnCount MaxOvalRadius MaxTextWidth MinActivationForDisplay
    }
Variables: { ColumnWidth RowHeight }
Setup: {
        $ColumnWidth = int( $EffectiveWidth / $ColumnCount );
        $RowHeight   = int( $EffectiveHeight / $EntriesPerColumn );
    }
DrawIt: {
        my @concepts_with_activation = SLTM::GetTopConcepts(10);
        my ( $row, $col ) = ( -1, 0 );
        for (@concepts_with_activation) {
            last if $col >= $ColumnCount;
            next unless $_->[1] > $MinActivationForDisplay;
            $row++;
            if ( $row >= $EntriesPerColumn ) {
                $row = 0;
                $col++;
            }
            DrawNode(
                $_,
                $XOffset + $Margin + $col * $ColumnWidth,
                $YOffset + $Margin + $row * $RowHeight
            );

        }
    }
ExtraStuff: {
        sub DrawNode {
            my ( $con_ref, $left, $top ) = @_;
            my ( $concept, $activation, $raw_activation, $raw_significance ) = @{$con_ref};
            my $radius = $activation * $MaxOvalRadius;

            #main::message("Rad: $radius");
            $Canvas->createOval(
                $left + 2 + $MaxOvalRadius - $radius,
                $top + 2 + $MaxOvalRadius - $radius,
                $left + 2 + $MaxOvalRadius + $radius,
                $top + 2 + $MaxOvalRadius + $radius,
                Style::NetActivation( int($raw_significance) ),
            );
            my $text = $concept->as_text();
            $text = substr( $text, 0, $MaxTextWidth );
            $Canvas->createText(
                $left + 6 + 2 * $MaxOvalRadius,
                $top + 2 + $MaxOvalRadius,
                -anchor => 'w',
                -text   => $text,
            );
        }

    }
}

1;

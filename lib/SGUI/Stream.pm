SeqseeDisplay Stream is {
ConfigNames: { EntriesPerColumn ColumnCount }
Variables: { ColumnWidth RowHeight }
Setup: {
        $ColumnWidth = int( $EffectiveWidth / $ColumnCount );
        $RowHeight   = int( $EffectiveHeight / $EntriesPerColumn );

    }
DrawIt: {
        DrawThought(
            $SStream::CurrentThought,
            $XOffset + $Margin / 2, $YOffset,
            1,    # i.e., is current tht
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
                0,    # not current tht
            );
        }
    }
ExtraStuff: {
        sub DrawThought {
            my ( $tht, $left, $top, $is_current ) = @_;
            my $hit_intensity = $SStream::thought_hit_intensity{$tht};
            $Canvas->createRectangle(
                $left, $top,
                $left + $ColumnWidth,
                $top + $RowHeight,
                Style::ThoughtBox( $hit_intensity, $is_current ),
            );
            $Canvas->createText(
                $left + 1, $top + 1,
                -anchor => 'nw',
                -text   => $tht->as_text(),
                Style::ThoughtHead(),
            );
            my $fringe = $tht->get_stored_fringe() or return;
            my $count  = 0;
            for ((@$fringe)[0..2]) {
                my ( $component, $activation ) = @$_;
                $count++;
                $Canvas->createText(
                    $left + 10, $top + 15 * $count,
                    -text   => $component,
                    -anchor => 'nw',
                    Style::ThoughtComponent( $activation,
                        $SStream::hit_intensity{$component},
                    ),
                );
            }
        }
    }
}
1;

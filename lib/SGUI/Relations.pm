SeqseeDisplay Relations is {
ConfigNames: { RowCount End1Offset End2Offset StrengthOffset SimplicityOffset TypeOffset Font }
Variables: {
        row_height ystart end1_x end2_x strength_x simplicity_x type_x rectangle_left
            rectangle_right
    }
Setup: {
        $row_height      = $EffectiveHeight / $RowCount;
        $ystart          = $YOffset + $Margin + 10;
        $end1_x          = $XOffset + $Margin + $End1Offset;
        $end2_x          = $XOffset + $Margin + $End2Offset;
        $strength_x      = $XOffset + $Margin + $StrengthOffset;
        $simplicity_x    = $XOffset + $Margin + $SimplicityOffset;
        $type_x          = $XOffset + $Margin + $TypeOffset;
        $rectangle_left  = $XOffset + $Margin;
        $rectangle_right = $XOffset + $Width - $Margin;
    }
DrawIt: {
        my $ypos      = $ystart;
        my $count     = 0;
        my @relations = values %SWorkspace::relations;
        my @compound  = grep { UNIVERSAL::isa( $_, 'Transform::Numeric' ) } @relations;
        my @simple    = grep { not UNIVERSAL::isa( $_, 'Transform::Structural' ) } @relations;
        for my $reln ( @compound, @simple ) {
            if ( $count % 2 == 0 ) {
                my $id = $Canvas->createRectangle(
                    $rectangle_left,  $ypos,
                    $rectangle_right, $ypos + $row_height,
                    -fill    => '#CCFFDD',
                    -outline => '',
                );
                $Canvas->lower($id);
            }
            DrawRelation( $reln, $ypos );
            $ypos += $row_height;
            $count++;
        }
    }
ExtraStuff: {

        sub DrawRelation {
            my ( $reln, $ypos ) = @_;
            my ( $end1, $end2 ) = $reln->get_ends();
            $Canvas->createText(
                $strength_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => sprintf( "%5.2f", $reln->get_strength() )
            );
            $Canvas->createText(
                $simplicity_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => sprintf( "%5.2f", $reln->get_type()->get_complexity() )
            );
            $Canvas->createText(
                $end1_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => $end1->get_bounds_string()
            );
            $Canvas->createText(
                $end2_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => $end2->get_bounds_string()
            );
            $Canvas->createText(
                $type_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => $reln->get_type()->as_text()
            );
        }

    }
}

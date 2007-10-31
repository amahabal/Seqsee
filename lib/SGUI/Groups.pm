SeqseeDisplay Groups is {
ConfigNames: { RowCount EndsOffset StrengthOffset CategoriesOffset Font }
Variables: {
        row_height ystart ends_x strength_x categories_x rectangle_left rectangle_right
    }
Setup: {
        $row_height      = $EffectiveHeight / $RowCount;
        $ystart          = $YOffset + $Margin + 10;
        $ends_x          = $XOffset + $Margin + $EndsOffset;
        $strength_x      = $XOffset + $Margin + $StrengthOffset;
        $categories_x    = $XOffset + $Margin + $CategoriesOffset;
        $rectangle_left  = $XOffset + $Margin;
        $rectangle_right = $XOffset + $Width - $Margin;
    }
DrawIt: {
        my $ypos      = $ystart;
        my $count     = 0;
        my @groups = SWorkspace->GetGroups();
        for my $group ( @groups ) {
            if ( $count % 2 == 0 ) {
                my $id = $Canvas->createRectangle(
                    $rectangle_left,  $ypos,
                    $rectangle_right, $ypos + $row_height,
                    -fill    => '#CCFFDD',
                    -outline => '',
                );
                $Canvas->lower($id);
            }
            DrawGroup( $group, $ypos );
            $ypos += $row_height;
            $count++;
        }
    }
ExtraStuff: {

        sub DrawGroup {
            my ( $group, $ypos ) = @_;
            $Canvas->createText(
                $strength_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => sprintf( "%5.2f", $group->get_strength() )
            );
            $Canvas->createText(
                $ends_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => $group->get_bounds_string()
            );

            my $categories_string = $group->get_categories_as_string();
            $Canvas->createText(
                $categories_x, $ypos,
                -anchor => 'nw',
                -font   => $Font,
                -text   => $categories_string
            );
        }

    }
}

SeqseeDisplay Rules is {
ConfigNames: { RowCount RejectionTimeOffset NameOffset}
Variables: { rejection_x name_x ystart row_height}
InitialCode: { }
Setup: { 
        $rejection_x = $XOffset + $Margin + $RejectionTimeOffset;
        $name_x = $XOffset + $Margin + $NameOffset;
        $ystart = $YOffset + $Margin + 10;
        $row_height = $EffectiveHeight / $RowCount;
}
DrawIt: {
        my %rules = (SRule->GetListOfSimpleRules(),
                     SRule->GetListOfCompoundRules()
                         );
        my $ypos = $ystart;
        while (my($k, $v) = each %rules) {
            $Canvas->createText($name_x, $ypos, -anchor => 'nw',
                                -text => $v->as_text()
                                    );
            $Canvas->createText($rejection_x, $ypos, -anchor => 'nw',
                                    -text => $v->GetRejectTime());
            $ypos += $row_height;
        }

 }
ExtraStuff: { }
}
1;

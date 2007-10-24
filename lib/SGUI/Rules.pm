SeqseeDisplay Rules is {
ConfigNames: { RowCount }
Variables: { xpos ystart row_height}
InitialCode: { }
Setup: { 
        $xpos = $XOffset + $Margin + 10;
        $ystart = $YOffset + $Margin + 10;
        $row_height = $EffectiveHeight / $RowCount;
}
DrawIt: {
        my %rules = (SRule->GetListOfSimpleRules(),
                     SRule->GetListOfCompoundRules()
                         );
        my $ypos = $ystart;
        while (my($k, $v) = each %rules) {
            $Canvas->createText($xpos, $ypos, -anchor => 'nw',
                                -text => $v->as_text()
                                    );
            $ypos += $row_height;
        }

 }
ExtraStuff: { }
}
1;

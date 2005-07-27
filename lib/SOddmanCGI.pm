# CGI specific oddman related routines...

sub SOddman::no_dice {
    print "<br>\nSorry, no dice!<br>\n";
}

sub SOddman::drewBlank {
    print "<br>\n No, drew a blank there!<br>\n";
}

sub SOddman::printLn {
    print shift, "<br>\n";
}

sub SOddman::attToDistinguish {
    my ($att) = @_;
    print
        "It appears that the attribute '$att' can be used to find the odd man<br>\n";
}

sub SOddman::fragment {
    my $what = shift;
    print span( { class => "fragment" }, " $what " );
}

sub SOddman::category {
    my $what = shift;
    print span( { class => "category" }, " $what " );
}

sub SOddman::showWhatsOdd {
    my ( $what_str, $catname ) = @_;
    print "<br> The odd man is: ";
    SOddman::fragment($what_str);
    print "Everything else is an instance of the category ";
    SOddman::category($catname);
    print "<br>\n";

}

sub SOddman::appearsButNot {
    my ( $what_str, $catname ) = @_;
    SOddman::fragment($what_str);
    print
        " can be construed to be an odd man out: it is the only one that is an instance of the category ";
    SOddman::category($catname);
    print "I shall continue to seek other solutions.<br><br>\n\n";
}

sub SOddman::allInstanceOf {
    my ($catname) = @_;
    print "<br> Everything seems to be an instance of the category ";
    SOddman::category($catname);
    print "It might be instructive to dwell deeper here!<br\n";
}

sub SOddman::Display_is_instance {
    my ( $string, $cat, $bindings ) = @_;
    print "<li> ";
    SOddman::fragment($string);
    if ($bindings) {
        print "Yes, This is an instance\n";
    }
    else {
        print "No, this is NOT an instance\n";
    }
}

1;

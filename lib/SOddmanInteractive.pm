# For the text based version

sub SOddman::no_dice{
  print "\n\n Sorry, no dice!\n\n";
}

sub SOddman::printLn{
  print shift, "\n\n";
}

sub SOddman::showWhatsOdd{
  my ($what_str, $catname ) = @_;
  
  print "\n\nThe odd man is:\n\n$what_str\n\n. Everything else is an instance of the category\n\n$catname\n\n";

}

1;

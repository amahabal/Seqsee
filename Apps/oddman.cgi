#!/l/perl-5.8.3/bin/perl
 
use CGI qw/:standard/;
use CGI::Carp qw{fatalsToBrowser};
# use CGI::HTMLError;
use lib "/u/amahabal/site_perl/lib/5.8.3";
use lib "/u/amahabal/site_perl/lib/site_perl/5.8.3";
use lib "/u/amahabal/site_perl/lib/sun4-solaris";
use S;

use SUtil;
use SOddman;
use SOddmanCGI;
our @cats = ( $S::ascending, $S::descending, $S::mountain );
our @blemishes = ( $S::double, $S::triple, $S::ntimes );

$| = 1;

my $style = "oddman.css";

my $q = new CGI;


print $q->header(), $q->start_html({-style => $style ,
				    -title => "The Seqsee Odd man!"});

if ($q->param('example')) {
  my $example_name = $q->param('example');
  print "Aha! I have been asked to do example $example_name\n";
}


print SBuiltObj->new_deep(1, 2, 3);
process_input();
show_form();

print "############";
print $q->end_html();

sub process_input{
  if ($q->param) {
    my @seq_fragments;
    for (1..6) {
      push @seq_fragments, $q->param("seq_$_") if param("seq_$_") =~ /\S/;
    }
    # print "You gave ", scalar(@seq_fragments), " parts!<br>\n";

    for (@seq_fragments) {
      s/^\s*//;
      s/\s*$//;
    }

    print h2("Stuff I got to process:");
    print "<ul> ";
    print "<li> $_\n" for @seq_fragments;
    print "</ul>\n";

    $_ = [split(/\s+/, $_)] for @seq_fragments;


    if (@seq_fragments < 3) {
      print "I need at least three elements for Oddman to be discovered!<br>";
      return;
    }

    my $cat = process_oddman(@seq_fragments);

    return unless $cat;

    my @test_fragments;
    for (1..6) {
      push @test_fragments, param("test_$_") 
	if param("test_$_") =~ /\S/;
    }

    for (@test_fragments) {
      s/^\s*//;
      s/\s*$//;
      $_ = [ split(/\s+/, $_) ];
    }

    if (@test_fragments) {
      print "<ul>\n";

      for (@test_fragments) {
	my $bindings = process_test( $cat, $_ );
	SOddman::Display_is_instance( 
				     join(", ", @$_), 
				     $cat, 
				     $bindings);
      }
      print "</ul>\n";

    }
    
  }
}

sub show_form{
  print $q->start_form( -action => 'http://www.cs.indiana.edu/cgi-pub/amahabal/oddman.cgi');
  
  print $q->h2("Sequence fragments for oddman");
  
  print "<table border=\"1\">\n";
  for (1..6) {
    print "<tr> <td> Fragment $_ </td><td> ", textfield("seq_".$_), "</td></tr>\n\n";
  }
  print "</table>\n\n";
  
  print $q->h2("Sequence fragments for testing learned category");
  
  print "<table border=\"1\">\n";
  for (1..6) {
    print "<tr> <td> Fragment $_ </td><td> ", textfield("test_".$_), "</td></tr>\n\n";
  }
  print "</table>\n\n";
  
  print $q->submit();

  print $q->end_form();
}

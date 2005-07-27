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
use SOddman::Examples;
our @cats = ( $S::ascending, $S::descending, $S::mountain );
our @blemishes = ( $S::double, $S::triple, $S::ntimes );

our $blemish_and_cat_ref = [ @cats, @blemishes ];


$| = 1;

my $style = "oddman.css";

my $q = new CGI;



print $q->header(), $q->start_html({-style => $style ,
				    -title => "The Seqsee Odd man!"});

if ($q->param('example')) {{
  my $example_name = $q->param('example');
  #print "Aha! I have been asked to do example $example_name\n";
  my $example = $ {"SOddman::Examples::example_$example_name"};
  unless ($example) {
    print $q->h2("Error...");
    print "I did not find the example in my database. Strange. I'll just pretend that you were trying to run an example from scratch...";
    last;
  }
  #print "example seq_1 is $example->{seq_1}\n";
  #print "It is example $example\n";
  #print "Q was $q...";
  $q = new CGI({ %$example });
  #print "... and now it is $q. Param 1 is ", $q->param('seq_1');
}}



eval { process_input() };
if ($@) {
  
  print $q->h2("Error! ");
  print "It appears that there was some problem with the input or with my processing: here is the error message: ";
  my $msg = $@;
  print $q->blockquote($msg);
  print "I am sorry, but I have to give up processing this particular input";
}
show_form();

print "############";
print $q->end_html();

sub process_input{
  if ($q->param) {
    my @seq_fragments;
    for (1..6) {
      push @seq_fragments, $q->param("seq_$_") if $q->param("seq_$_") =~ /\S/;
    }
    # print "You gave ", scalar(@seq_fragments), " parts!<br>\n";

    for (@seq_fragments) {
      s/^\s*//;
      s/\s*$//;
    }
    @seq_fragments = grep { $_ } @seq_fragments;
    
    if (@seq_fragments < 3) {
      if (@seq_fragments) {
	print "I need at least three elements for Oddman to be discovered!<br>";
	return;

      } else {
	return;
      }
    } 



    print h2("Inputs I received:");
    print "<ul> ";
    print "<li> $_\n" for @seq_fragments;
    print "</ul>\n";

    # $_ = [split(/\s+/, $_)] for @seq_fragments;


    print "<hline>\n";
    print $q->h2("Analysis");

    my $cat = process_oddman(@seq_fragments);

    return unless $cat;

    my @test_fragments;
    for (1..6) {
      push @test_fragments, $q->param("test_$_") 
	if $q->param("test_$_") =~ /\S/;
    }

    for (@test_fragments) {
      s/^\s*//;
      s/\s*$//;
    }

    @test_fragments = grep { $_ } @test_fragments;
    return unless @test_fragments;

    print $q->h2("Testing for category membership");

    #$_ = [ split(/\s+/, $_) ] for @test_fragments;

    print "<ul>\n";

    for (@test_fragments) {
      my $bindings = process_test( $cat, $_ );
      SOddman::Display_is_instance( 
				   $_, # join(", ", $_), 
				   $cat, 
				   $bindings);
    }
    print "</ul>\n";
    
  }
}

sub show_form{
  print $q->start_form( -action => 'http://www.cs.indiana.edu/cgi-pub/amahabal/oddman.cgi');

  print $q->h2("Another task");
  #print $q->h4("Sequence fragments for oddman");
  
  print "<table border=\"5\" bgcolor=\"#cccc99\"> \n";
  print "<tr> <th> Input for oddman <th> Fragments for Tests </tr>\n";
  print "<tr><td>";

  print "<table border=\"1\" cellpadding=\"5\" bgcolor=\"#cccc99\">\n";
  for (1..6) {
    print "<tr> <td> Fragment $_ </td><td> ", $q->textfield("seq_".$_), "</td></tr>\n\n";
  }
  print "</table>\n\n";
  
  # print $q->h4("Sequence fragments for testing");
  print "<td>";
  print "<table border=\"1\" cellpadding=\"5\" bgcolor=\"#cccc99\">\n";
  for (1..6) {
    print "<tr> <td> Fragment $_ </td><td> ", $q->textfield("test_".$_), "</td></tr>\n\n";
  }
  print "</table>\n\n";
  print "</table>\n\n";

  print $q->submit();

  print $q->end_form();
}

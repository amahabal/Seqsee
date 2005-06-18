use Perl6::Subs;
use Getopt::Long;

my $diff_only;

GetOptions("diff=i" => \$diff_only);

my $filename = "__print";
my $repos_path = "/u/amahabal/SVN2";

my $revision = `svnlook youngest /u/amahabal/SVN2`;
$revision =~ s#\D##g;

my $last_change = `svnlook date -r $revision $repos_path`;
$last_change =~ m#^\S+\s+(\S+).*\((.*)\)#;
$last_change = "on $2, at $1";




my $cwd_url = `svn info| grep URL`;
$prefix_to_remove = $cwd_url;
#print "CWD_URL = '$cwd_url'\n";
$prefix_to_remove = $cwd_url;
$prefix_to_remove =~ s#^URL: file://$repos_path/##;
chomp($prefix_to_remove);
print "prefix to remove: '$prefix_to_remove'\n";
#exit;




open OUT, ">$filename.tex";
print_preamble();
print_title();
print_all_files();
print_postamble();
close OUT;
system "lmake $filename";

sub print_preamble(){
  print OUT << 'END';
\documentclass{article}
\usepackage{pslatex}
\begin{document}
\scriptsize
END
}

sub print_postamble{
  print OUT <<"END";
\\end{document}
END
}

sub print_title{
  my $comment;
  if ($diff_only) {
    $comment = "(changes since $diff_only)";
  }
  print OUT << "END";
\\title{Code dump, revision $revision $comment}
\\date{last change: $last_change}
\\author{Abhijit Mahabal}
\\maketitle
END
}

sub print_all_files{
  my @files = sort(<TODO lib/*.pm lib/*/*.pm lib/*/*/*.pm  t/*.t t/*/*.t t/*/*/*.t>);
  my %PrintOK;
  for (@files) {
    $PrintOK{$_} = 1;
  }
  if ($diff_only) {
    # Only print things that have changed since revision $diff_only
    print "Will print differences from $diff_only\n";
    %PrintOK = ();
    for my $rev ($diff_only + 1..$revision) {
      open IN, "svnlook changed -r $rev $repos_path|";
      while (my $in = <IN>) {
	chomp($in);
	$in = substr($in, 4);
	#print "$in\n";
	$in =~ s#^$prefix_to_remove/##;
	$PrintOK{$in} = 1;
	print "Will print '$in'\n";
      }
    }
  }

  for (@files) {
    print_file($_) if $PrintOK{$_};
  }
}

sub print_file($file){
  #print "Printing $file\n";
  my $file_ = $file;
  $file_ =~ s#_#\\_#g;
  print OUT "\\section*{$file_}\n";
  open IN, $file;
  print OUT "\\begin{verbatim}\n";
  while ($_ = <IN>) { print OUT;}
  print OUT "\\end{verbatim}\n";
  close IN;
}

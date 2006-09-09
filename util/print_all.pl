use Perl6::Subs;
use Getopt::Long;
use Smart::Comments;

my $diff_only;
my $SHOW_CODE_FILES = 1;
my $SHOW_TEST_FILES = 0;
my $DYNAMIC_ONLY = 0;

GetOptions("diff=i" => \$diff_only,
           "code!"  => \$SHOW_CODE_FILES,
           "test!"  => \$SHOW_TEST_FILES,
           "dynamic!" =>  \$DYNAMIC_ONLY,
               );

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


my $reviewing_tex = << 'END';
\normalsize
\cleardoublepage
\section*{Reviewing Code}
\begin{longtable}{ccl|p{3in}}
\textbf{Rev} &\textbf{Pass}  & \textbf{filename}&\textbf{comments and bugs}\\\hline
END

my $reviewing_tex_end = <<'END';
\end{longtable}
\cleardoublepage
\section*{Comments and Bugs Index}
\begin{enumerate}
END

for (1..50){
    $reviewing_tex_end .= "\\item\n";
}
$reviewing_tex_end .= "\\end{enumerate}\n";

open OUT, ">$filename.tex";
print_preamble();
print_title();
print_all_files();
print OUT $reviewing_tex;
print OUT $reviewing_tex_end;
print_postamble();
close OUT;
system "lmake $filename";

sub print_preamble(){
  print OUT << 'END';
\documentclass[twoside]{article}
\usepackage{pslatex}
\usepackage{pifont}
\usepackage{longtable}
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
    my @code_files = sort(<Seqsee.pl lib/*.pm lib/*/*.pm lib/*/*/*.pm config/*>);
    my @test_files = sort(<t/*.t t/*/*.t t/*/*/*.t t/lib/STest/*.pm t/lib/STest/*/*.pm>);
    my @files;
    push(@files, @code_files) if $SHOW_CODE_FILES;
    push(@files, @test_files) if $SHOW_TEST_FILES;

    if ($DYNAMIC_ONLY) {
        @files = sort(<lib/SCF/*.pm lib/SThought/*.pm>);
    }
    
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

  for (@files) { ### Generating Latex ===>           Done[%]
    print_file($_) if $PrintOK{$_};
  }
}

sub print_file($file){
  #print "Printing $file\n";
  my $file_ = $file;
  $file_ =~ s#_#\\_#g;
  print OUT "\\section*{$file_}\n";
  my $open_what;
  
  if ($file =~ m#All\.pm$#) { # SCF/All and SThought/All
      $open_what = $file;
  } elsif ($file =~ m#\.p.$#) {
      $open_what =     "perltidy -l=100 -st $file | ";
  } else {
      $open_what = $file;
  }

  open IN, $open_what;
  print OUT "\\begin{verbatim}\n";
  while ($_ = <IN>) { print OUT;}
  print OUT "\\end{verbatim}\n";
  close IN;
  $reviewing_tex .= "\\ding{111} & \\ding{111} & $file_ & \\\\\\hline\n";
}

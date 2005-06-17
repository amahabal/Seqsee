use Perl6::Subs;

my $filename = "__print";

my $revision = `svn info| grep 'Rev:'`;
$revision =~ s#\D##g;
my $last_change = `svn info| grep Date`;
$last_change =~ m#\((.*)\)#;
$last_change = $1;

my $pat = $ARGV[0];
$pat ||= ".*";


open OUT, ">$filename.tex";
print_preamble();
print_title();
print_all_files();
print_postamble();
close OUT;
system "lmake $filename";

sub print_preamble(){
  print OUT << 'END';
\documentclass[8pt]{article}
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
  print OUT << "END";
\\title{Code dump, revision $revision}
\\date{last change: $last_change}
\\author{Abhijit Mahabal}
\\maketitle
END
}

sub print_all_files{
  foreach (<lib/*.pm lib/*/*.pm lib/*/*/*.pm>) {
    print_file($_) if $_ =~ /$pat/o;
  }

  foreach (<t/*.t t/*/*.t t/*/*/*.t>) {
    print_file($_) if $_ =~ /$pat/o;
  }

}

sub print_file($file){
  #print "Printing $file\n";
  print OUT "\\section*{$file}\n";
  open IN, $file;
  print OUT "\\begin{verbatim}\n";
  while ($_ = <IN>) { print OUT;}
  print OUT "\\end{verbatim}\n";
  close IN;
}

for my $f (<pod/*.pod pod/*/*.pod>) {
  my $f2 = $f; $f2 =~ s#^pod/##; $f2 =~ s#.pod$#.html#;
  system " pod2html --noindex --title=$f --infile=$f --htmlroot=http://www.cs.indiana.edu/~amahabal/seqsee --podroot=./pod --podpath=.:./sdd --outfile=/u/amahabal/.hyplan/seqsee/$f2";
}


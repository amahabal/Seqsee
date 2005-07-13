my $path = "/l/cgi/amahabal/site_perl/lib/site_perl/5.8.3";

for (<lib/*.pm lib/*/*.pm lib/*/*/*.pm>) {
  print "cp $_ $path/$_\n";
}


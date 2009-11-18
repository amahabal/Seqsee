#!perl

use Test::More tests => 9;

BEGIN {
  use_ok('Seqsee');
  use_ok('Seqsee::Object');
  use_ok('Seqsee::Anchored');
  use_ok('Seqsee::Element');

  use_ok('Seqsee::Mapping');
  use_ok('Seqsee::Mapping::Structural');
  use_ok('Seqsee::Mapping::Dir');
  use_ok('Seqsee::Mapping::Position');
  use_ok('Seqsee::Mapping::MetoType');

}

diag("Testing Seqsee $Seqsee::VERSION, Perl $], $^X");

#my $e = Seqsee::Element->create(5, 2);
#my $f = Seqsee::Object::CreateObjectFromStructure([2, 3, [4, 4], 5]);
#print $f, "\n";
#print "####################\n", join(';', @$f), "\n";

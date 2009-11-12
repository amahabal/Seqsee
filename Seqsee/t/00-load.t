#!perl -T

use Test::More tests => 4;

BEGIN {
  use_ok('Seqsee');
  use_ok('Seqsee::Object');
  use_ok('Seqsee::Anchored');
  use_ok('Seqsee::Element');
}

diag("Testing Seqsee $Seqsee::VERSION, Perl $], $^X");

use Test::More tests=> 11;
use Test::Exception;
use blib;

use_ok("SMCat");
use_ok("SCat");




MCAT: {
  can_ok("SMCat", qw{new register});
  my $m1 = new SMCat name => "foo";
  isa_ok($m1, "SMCat");
  ok(not(defined $SMCat::MCats{"foo"}), "not registered on creation");
  is($m1->{name}, "foo", "Name set properly");
  
  $m1->register();
  ok(defined ($SMCat::MCats{"foo"}), "not registered on creation");
  is($SMCat::MCats{foo}, $m1, "Right thing registered");
  
  # Something can be registered only once:
  my $m2 = new SMCat name => "foo";
  dies_ok  { $m2->register() }, "something of that name already exists";
  lives_ok { $m1->register() }, "but registering the same object twice is okay";

  my $m3;
  dies_ok { $m3 = new SMCat() }, "must provide name for SMCat";
  our $foo_cat = $m1;
}

1;

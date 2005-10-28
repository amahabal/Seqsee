use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 5; }

#use MyFilter;
use Test::MockObject;

BEGIN {
  Test::MockObject->fake_module('SCF::test');

  sub SCF::test::run {
    my $args = shift;
    return $args->{foo};
  }
}


my $cl_def  = new SCodelet( "test", 10 );
my $cl_def2 = new SCodelet( "test", 15, foo => 1 );
my $cl_def3 = new SCodelet( "test", 20, foo => 2 );

ok( SCoderack->get_urgencies_sum == 0 );

SCoderack->add_codelet($cl_def);
ok( SCoderack->get_urgencies_sum == 10 );
ok( SCoderack->get_codelet_count == 1 );

SCoderack->add_codelet($cl_def2);
SCoderack->add_codelet($cl_def3);

my $cl  = SCoderack->get_next_runnable;
my $urg = $cl->[1];

ok( SCoderack->get_urgencies_sum == 45 - $urg );
ok( SCoderack->get_codelet_count == 2 );


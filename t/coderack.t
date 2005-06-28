use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 11; }

#use MyFilter;
use Test::MockObject;

BEGIN {
  Test::MockObject->fake_module('SCF::test');

  sub SCF::test::run {
    my $args = shift;
    return $args->{foo};
  }
}

use SCoderack;
use SCodelet;

my $cl_def  = new SCodelet( "test", 10 );
my $cl_def2 = new SCodelet( "test", 15, foo => 1 );
my $cl_def3 = new SCodelet( "test", 20, foo => 2 );

ok( $SCoderack::last_bucket == 9 );
ok( $SCoderack::urgencies_sum == 0 );

SCoderack->add_codelet($cl_def);
ok( $SCoderack::last_bucket == 0 );
ok( $SCoderack::urgencies_sum == 10 );
ok( $SCoderack::buckets[0][0] eq $cl_def );
ok( $SCoderack::bucket_sum[0] == 10 );
ok( $SCoderack::codelet_count == 1 );

SCoderack->add_codelet($cl_def2);
SCoderack->add_codelet($cl_def3);

my $cl  = SCoderack->choose_codelet;
my $urg = $cl->[1];

ok( $SCoderack::last_bucket == 2 );
ok( $SCoderack::urgencies_sum == 45 - $urg );
ok( $SCoderack::bucket_sum[0] == 10 or $urg == 10 );
ok( $SCoderack::codelet_count == 2 );


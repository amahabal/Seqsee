use blib;
use lib 't/lib';
use STest::SCat;
use STest::SCat::specific;

my @test_class_instances =
    (
        STest::SCat->new(),
        STest::SCat::specific->new(),
            );
Test::Class->runtests(@test_class_instances);


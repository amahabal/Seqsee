package STest::SReln;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use Class::Multimethods;
multimethod find_reln;

my $o123  = SObject->quik_create([1,2,3], $S::ASCENDING);
my $o123b = SObject->quik_create([1,2,3], $S::ASCENDING);
my $o1234  = SObject->quik_create([1,2,3,4], $S::ASCENDING);
my $o23  = SObject->quik_create([2,3], $S::ASCENDING);
my $o234  = SObject->quik_create([2,3,4], $S::ASCENDING);

my $o1123  = SObject->quik_create([[1,1], 2,3], $S::ASCENDING);
my $o1223  = SObject->quik_create([1,[2,2],3], $S::ASCENDING);
my $o12223  = SObject->quik_create([1,[2,2,2],3], $S::ASCENDING);


sub simple :Test(8){
    my $reln;

    $reln = find_reln(1,1);
    ok( $reln->get_text() eq "same" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(0,0);
    ok( $reln->get_text() eq "same" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(1,2);
    ok( $reln->get_text() eq "succ" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(2,1);
    ok( $reln->get_text() eq "pred" );
    isa_ok( $reln, "SReln::Simple");
}

sub reln_123_123b :Test{
    my $reln = find_reln($o123, $o123b);
    isa_ok($reln, "SReln::Compound");
}

1;

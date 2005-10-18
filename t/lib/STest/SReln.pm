package STest::SReln;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use Class::Multimethods;
multimethod find_reln;

sub simple :Test(4){
    my $reln;

    $reln = find_reln(1,1);
    ok( $reln->get_text() eq "same" );

    $reln = find_reln(0,0);
    ok( $reln->get_text() eq "same" );

    $reln = find_reln(1,2);
    ok( $reln->get_text() eq "succ" );

    $reln = find_reln(2,1);
    ok( $reln->get_text() eq "pred" );

}



1;

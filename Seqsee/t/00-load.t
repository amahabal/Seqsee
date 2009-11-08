#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Seqsee' );
}

diag( "Testing Seqsee $Seqsee::VERSION, Perl $], $^X" );

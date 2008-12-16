use strict;
use lib 'genlib';
use Test::Seqsee;
use SColor;

plan tests => 7;

my @tests = ( [ 1, 0, 25, '#404040' ],
[0,28,43,'#6E4F4F'],
[86,28,43,'#606E4F'],
[162,54,29,'#224A3E'],
[200,61,18,'#11242E'],
[264,52,87,'#996ADE'],
[322,28,92,'#EBA9D3'],
 );
for my $t (@tests) {
    my ( $h, $s, $v, $res ) = @$t;
    cmp_ok( SColor::HSV2Color( $h, $s, $v ), 'eq', $res );
}

use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;
plan tests => 12;

use Class::Multimethods;
for (qw{find_reln plonk_into_place}) {
    multimethod $_;
}

SWorkspace->init( { seq => [qw( 1 2 3 4 3 1 1 2 3 1 2 2 3 4 1 2 3 3 4 5 )] } );

my $WSO_ra = find_reln( $SWorkspace::elements[0], $SWorkspace::elements[1] );
$WSO_ra->insert();

my $WSO_rb = find_reln( $SWorkspace::elements[4], $SWorkspace::elements[3] );
$WSO_rb->insert();

my $type = $WSO_ra->get_type();
isa_ok $type, q{SRelnType::Simple};
is $WSO_rb->get_type(), $type, "Memoized!";

## Now to more complex relations.
my $o1 = SObject->QuickCreate( [ [ 1, 1 ], 2, 3 ], $S::ASCENDING );
my $o_plonked = plonk_into_place( 5, $DIR::RIGHT, $o1 );
ok( $o_plonked, );
instance_of_cat_ok( $o_plonked, $S::ASCENDING );
instance_of_cat_ok( $o_plonked->[0], $S::SAMENESS );
my $o_plonked2
    = plonk_into_place( 9, $DIR::RIGHT, SObject->QuickCreate( [ 1, [ 2, 2 ], 3, 4 ], $S::ASCENDING ) );
my $o_plonked3 = plonk_into_place( 14, $DIR::RIGHT,
    SObject->QuickCreate( [ 1, 2, [ 3, 3 ], 4, 5 ], $S::ASCENDING ) );
instance_of_cat_ok( $o_plonked2, $S::ASCENDING );
instance_of_cat_ok( $o_plonked2->[1], $S::SAMENESS );
instance_of_cat_ok( $o_plonked3, $S::ASCENDING );
instance_of_cat_ok( $o_plonked3->[2], $S::SAMENESS );

## os: $o_plonked, $o_plonked2, $o_plonked3
my $WSO_rc = find_reln($o_plonked, $o_plonked2, $S::ASCENDING);
$WSO_rc->insert();
my $WSO_rd = find_reln($o_plonked2, $o_plonked3, $S::ASCENDING);
$WSO_rd->insert();

ok( $WSO_rc and $WSO_rd, );
my $type2 = $WSO_rc->get_type();
isa_ok $type2, q{SRelnType::Compound};

is $WSO_rd->get_type(), $type2, "Memoized!";
 

use strict;
use blib;
use Test::Seqsee;
plan tests => 40;

use SActivation;

sub CheckRawActSignificanceAndStability {
    my ( $act, $activation, $significance, $stability, $time ) = @_;
    is( $act->GetRawActivation(),               $activation );
    is( $act->GetRawSignificance(),             $significance );
    is( $act->GetStability(),                   $stability );
    is( $act->GetTimeToDecrementSignificance(), $time );
}

my $act = new SActivation;
CheckRawActSignificanceAndStability( $act, 1, 1, 100, 100 );

$act->Spike(50);
CheckRawActSignificanceAndStability( $act, 51, 1, 100, 100 );

$act->Decay() for 1 .. 10;
CheckRawActSignificanceAndStability( $act, 41, 1, 100, 90 );

$act->Spike(70);
CheckRawActSignificanceAndStability( $act, 100, 2, 100, 90 );

$act->Decay() for 1 .. 10;
CheckRawActSignificanceAndStability( $act, 90, 2, 100, 80 );

$act->Spike(70);
$act->Decay() for 1 .. 79;
CheckRawActSignificanceAndStability( $act, 21, 3, 100, 1 );
$act->Decay();
CheckRawActSignificanceAndStability( $act, 20, 2, 100, 100 );
$act->Decay() for 1 .. 19;
CheckRawActSignificanceAndStability( $act, 1, 2, 100, 81 );
$act->Decay();
CheckRawActSignificanceAndStability( $act, 1, 2, 100, 80 );

my @several = map { SActivation->new() } (1..100);
$_->Spike(50) for @several;

SActivation::DecayMany(\@several, 100);
CheckRawActSignificanceAndStability($several[3], 50, 1, 100, 99);

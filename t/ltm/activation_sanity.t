use strict;
use blib;
use Test::Seqsee;
plan tests => 5;

use Smart::Comments;
use SLTM;

sub DumpAndReload {
    my $fh = new File::Temp( TEMPLATE => 'XXXXX', SUFFIX => '.ltm', UNLINK => 0 );
    my $filename = $fh->filename;
    SLTM->Dump($fh);    # That also closes the filehandle

    SLTM->Clear();

    SLTM->Load($filename);
}

SLTM->Clear();

my $ascending_index  = SLTM::GetMemoryIndex($S::ASCENDING);
my $descending_index = SLTM::GetMemoryIndex($S::DESCENDING);
my @indices          = ( $ascending_index, $descending_index );
my @concepts         = ( $S::ASCENDING, $S::DESCENDING );

SLTM::SetSignificanceAndStabilityForIndex( $ascending_index,  5,  7 );  # Significance and Stability
SLTM::SetSignificanceAndStabilityForIndex( $descending_index, 12, 9 );

SLTM::SetRawActivationForIndex( $ascending_index,  30 );
SLTM::SetRawActivationForIndex( $descending_index, 25 );

SLTM::DecayAll();

is_deeply SLTM::GetRawActivationsForIndices( \@indices ), [ 29, 24 ];

my $choice = SLTM::ChooseIndexGivenIndex( \@indices );
ok( $choice eq $ascending_index or $choice eq $descending_index, );

$choice = SLTM::ChooseConceptGivenIndex( \@indices );
ok( $choice eq $S::ASCENDING or $choice eq $S::DESCENDING, );

$choice = SLTM::ChooseIndexGivenConcept( \@concepts );
ok( $choice eq $ascending_index or $choice eq $descending_index, );

$choice = SLTM::ChooseConceptGivenConcept( \@concepts );
ok( $choice eq $S::ASCENDING or $choice eq $S::DESCENDING, );


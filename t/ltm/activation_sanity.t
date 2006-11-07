use strict;
use blib;
use Test::Seqsee;
plan tests => 10;

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

SLTM::set_significance( $ascending_index,  5,  7 );    # Significance and Stability
SLTM::set_significance( $descending_index, 12, 9 );

SLTM::set_activation( $ascending_index,  30 );
SLTM::set_activation( $descending_index, 25 );

SLTM::DecayAll();

is_deeply SLTM::GetRawActivations( \@indices ), [ 29, 24 ];

my $choice = SLTM::ChooseIndexGivenIndex( \@indices );
ok( $choice eq $ascending_index or $choice eq $descending_index, );

$choice = SLTM::ChooseConceptGivenIndex( \@indices );
ok( $choice eq $S::ASCENDING or $choice eq $S::DESCENDING, );


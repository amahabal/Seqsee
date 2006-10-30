use strict;
use blib;
use Test::Seqsee;
plan tests => 10;

sub DumpAndReload {
    my $fh = new File::Temp( TEMPLATE => 'XXXXX', SUFFIX => '.ltm', UNLINK => 0 );
    my $filename = $fh->filename;
    SLTM->Dump($fh);    # That also closes the filehandle

    SLTM->Clear();

    SLTM->Load($filename);
}

SLTM->Clear();

my @Nodes;
for ( $S::ASCENDING, $S::DESCENDING,
    $S::LITERAL->build( { structure => 1 }, $S::LITERAL->build( { structure => 2 } ) ) )
{
    push @Nodes, GetExactFromMemory($_); # Also adds it.
}

# Test the OO interface to activation.
for (@Nodes) {
    $_->SetRawActivation(20, 10, 2);
}



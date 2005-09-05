package Seqsee;
use version;
our $VERSION = version->new( "0.0.3" );

sub run{
    my (@sequence) = @_;
    SWorkspace->clear(); SWorkspace->init(@sequence);
    SStream->clear();    SStream->init();
    SCoderack->clear();  SCoderack->init();
}

1;

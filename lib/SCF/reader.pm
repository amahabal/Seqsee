package SCF::reader;

sub run{
    shift;

    my $object = SWorkspace->read_object();

    if ( $object ) {
        SStream->add_thought( SThought->new( { core => $object }) );
    }
}

1;

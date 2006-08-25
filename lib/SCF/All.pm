use Compile::SCF;
[package] SCF::Reader
<run>
    my $object = SWorkspace->read_object();
    if (LOGGING_INFO() and $object) {
        my ($l, $r, $s) = ($object->get_left_edge,
                           $object->get_right_edge,
                           $object->get_structure,
                               );
        my $msg = "* Read Object: \t[$l,$r] $s\n";
        $logger->info( $msg );
    }

    if ($object) {
        # main::message("read an SAnchored!") if (ref $object) eq "SAnchored";
        SThought->create($object)->schedule();
    }
</run>

1;

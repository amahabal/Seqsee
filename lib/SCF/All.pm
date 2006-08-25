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

no Compile::SCF;
use Compile::SCF;
[package] SCF::CheckIfInstance
[param] obj!
[param] cat!
<run>
    $obj->describe_as($cat);
</run>

no Compile::SCF;
use Compile::SCF;
[package] SCF::SetLiteralCat
[param] object!
<run>
    my @structure;
    if ($object->get_metonym_activeness) {
        @structure = $object->get_metonym()->get_starred->get_structure();
    } else {
        @structure = 
            map { $_->get_structure }
                map { $_->get_effective_object } 
                    @{$object->get_parts_ref};
        ## @structure
    }
    
    my $lit_cat = $S::LITERAL->build({ structure => [@structure] });
    ## $lit_cat, ident $lit_cat
    my $bindings = $object->describe_as( $lit_cat );
    ## $bindings
    unless ($bindings) {
        confess "Hey, should NEVER have failed!";
    }
</run>
1;

ThoughtType SCat( $core ! ) does {
AS_TEXT: { return "Category " . $self->get_core()->as_text(); }
FRINGE: { FRINGE 100, $self->get_core(); }
ACTIONS: {
        my $cat = $self->get_core();
        return if $cat->isa('SCat::OfObj::Interlaced');

        my @objects_of_cat = SWorkspace::__GetObjectsBelongingToCategory($cat);
        my @overlapping_sets
            = SWorkspace::__FindSetsOfObjectsWithOverlappingSubgroups(@objects_of_cat)
            or return;

        for my $set (@overlapping_sets) {
            my @part_names = map { $_->as_text } @$set;
            CODELET 100, MergeGroups, { a => $set->[0], b => $set->[1] };

            # main::message( "I should perhaps merge @part_names ", 1);
        }

        # main::message( "Just testing! thinking about $cat");
    }
};
1;

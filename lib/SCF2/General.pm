CodeletFamily FocusOn( $what = {0} ) does {
NAME: { Focus On }
RUN: {
        if ($what) {
            ContinueWith( SThought->create($what) );
        }

        # Equivalent to Reader
        if ( SUtil::toss(««Codelet, FocusOn::HuntsSameness»») ) {
            SWorkspace::__CreateSamenessGroupAround($SWorkspace::ReadHead);
            return;
        }
        my $object = SWorkspace::__ReadObjectOrRelation() // return;
        ContinueWith( SThought->create($object) );
    }
};

CodeletFamily LookForSimilarGroups( $group ! ) does {
NAME: { Look for Similar Groups }
RUN: {
        my $wset = SWorkspace::__GetObjectsBelongingToSimilarCategories($group);
        return if $wset->is_empty();

        for ( $wset->choose_a_few_nonzero(3) ) {
            CODELET 50, FocusOn, { what => $_ };
        }
    }
};

CodeletFamily MergeGroups( $a !, $b ! ) does {
NAME: { Merge Groups }
RUN: {
        return if $a eq $b;
        SWorkspace::__CheckLiveness($a, $b) or return;
        my @items = SUtil::uniq(@$a, @$b);
        @items = SWorkspace::__SortLtoRByLeftEdge(@items);

        return if SWorkspace::__AreThereHolesOrOverlap(@items);
        my $new_group;
        TRY {
            my @unstarred_items = map { $_->GetUnstarred() } @items;
            ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
            SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
            $new_group = SAnchored->create(@unstarred_items);
            if ($new_group) {
                $new_group->set_underlying_ruleapp($a->get_underlying_reln()->get_rule());
                $a->CopyCategoriesTo($new_group);
                SWorkspace->add_group($new_group);
            }
        } CATCH {
          ConflictingGroups: { return }
        }

    }
}

CodeletFamily CleanUpGroup( $group ! ) does {
NAME: { Clean Up Group }
RUN: { 
        return unless SWorkspace::__CheckLiveness($group);
        my @edges = $group->get_edges();
        my @potential_cruft = SWorkspace::__GetObjectsWithEndsNotBeyond(@edges);
        SWorkspace::__DeleteNonSubgroupsOfFrom({ of => [$group],
                                                 from => \@potential_cruft,
                                             });
    }
}

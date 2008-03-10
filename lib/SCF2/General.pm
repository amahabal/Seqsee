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

CodeletFamily LookForSimilarGroups( $group!) does {
  NAME: {Look for Similar Groups}
  RUN: {
        my $wset = SWorkspace::__GetObjectsBelongingToSimilarCategories($group);
        return if $wset->is_empty();

        for ($wset->choose_a_few_nonzero(3)) {
            CODELET 50, FocusOn, { what => $_ };
        }
    }
}

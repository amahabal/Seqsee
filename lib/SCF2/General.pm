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
}

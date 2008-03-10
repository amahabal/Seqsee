CodeletFamily FocusOn( $what = {0} ) does {
NAME: { Focus On }
RUN: { 
        if ($what) {
            ContinueWith(SThought->create($what));
        }
    }
}

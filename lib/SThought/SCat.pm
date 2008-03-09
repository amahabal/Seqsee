ThoughtType SCat( $core ! ) does {
AS_TEXT: { return "Category " . $self->get_core()->as_text(); }
FRINGE: { FRINGE 100, $self->get_core(); }
ACTIONS: {
        main::message("Just testing! thinking about " . $self->get_core());
    }
};
1;

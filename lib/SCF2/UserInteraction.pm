CodeletFamily AskIfThisIsTheContinuation(   $relation={0}, $ruleapp={0}, $exception!, $expected_object!, $start_position!) does {
  NAME: {Ask if This is the Continuation}
  INITIAL: { multimethod '__PlonkIntoPlace'; }
  RUN: {
        unless ($relation or $ruleapp) {
            confess "Need relation or ruleapp";
        }

        my $success;
        if ($relation) {
            $success = $exception->AskBasedOnRelation($relation, '');
        } else {
            $success = $exception->AskBasedOnRuleApp($ruleapp, '');
        }

        if ($success) {
            my $plonk_result = __PlonkIntoPlace( $start_position,
                                                 $DIR::RIGHT,
                                                 $expected_object );
            unless ($plonk_result->PlonkWasSuccessful) {
                main::message("From $start_position, could not insert " . $expected_object->as_text);
            }
        }
    }
}

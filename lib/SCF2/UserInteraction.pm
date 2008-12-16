CodeletFamily AskIfThisIsTheContinuation(   $relation={0}, $group={0}, $exception!, $expected_object!, $start_position!, $known_term_count!) does {
  NAME: {Ask if This is the Intended Continuation}
  INITIAL: { multimethod '__PlonkIntoPlace'; }
  RUN: {
        return unless $SWorkspace::ElementCount == $known_term_count;

        unless ($relation or $group) {
            confess "Need relation or ruleapp";
        }

        my $success;
        if ($relation) {
            $success = $exception->AskBasedOnRelation($relation, '');
        } else {
            $success = $exception->AskBasedOnGroup($group, '');
        }

        return unless $success;
        my $plonk_result = __PlonkIntoPlace( $start_position,
                                             $DIR::RIGHT,
                                             $expected_object );
        return unless ($plonk_result->PlonkWasSuccessful);

        if ($relation) {
            # We can establish the new relation!
            my $transform = $relation->get_type();
            my $new_relation = SRelation->new({first => $relation->get_second(),
                                               second => $plonk_result->get_resultant_object(),
                                               type => $transform,
                                           });
            $new_relation->insert();
        } else {
            # We can extend the group!
            my $ruleapp = $group->get_underlying_reln() or return;
            my $transform = $ruleapp->get_rule()->get_transform();
            my $new_object = $plonk_result->get_resultant_object();
            my $new_relation = SRelation->new({first => $group->[-1],
                                               second => $new_object, 
                                               type => $transform,
                                           });
            $new_relation->insert() or return;
            $group->Extend($new_object, 1);
        }
    }
}

CodeletFamily MaybeAskTheseTerms( $core !, $exception ! ) does {
INITIAL: { use Class::Multimethods qw{createRule}; }
RUN: {
        my ( $type_of_core, $rule ) = get_core_type_and_rule($core);

        my $time_since_successful_extension
            = RulesAskedSoFar::TimeSinceRuleUsedToExtendSuccessfully($rule);
        my $time_since_unsuccessful_extension
            = RulesAskedSoFar::TimeSinceRuleUsedToExtendUnsuccessfully($rule);

        if ($time_since_successful_extension) {
            CODELET 100, MaybeAskUsingThisGoodRule,
                {
                core      => $core,
                rule      => $rule,
                exception => $exception,
                };
        }
        elsif ($time_since_unsuccessful_extension) {
            CODELET 50, MaybeAskUsingThisUnlikelyRule,
                {
                core      => $core,
                rule      => $rule,
                exception => $exception,
                };
        }
        else {
            my $success;
            if ( $type_of_core eq 'relation' ) {
                SLTM::SpikeBy( 10, $core->get_type() );

                my $strength = $core->get_strength;

                # main::message("Strength for asking: $strength", 1);
                return unless SUtil::toss( $strength / 100 );
            }
            else {
                CODELET 100, DoTheAsking,
                    {
                    core      => $core,
                    exception => $exception,
                    };

            }
            if ($success) {
                RulesAskedSoFar::AddRuleToSuccessList($rule);
            }
            else {
                RulesAskedSoFar::AddRuleToFailureList($rule);
            }
        }
    }
FINAL: {

        sub get_core_type_and_rule {
            my ($core) = @_;
            my $type_of_core =
                  UNIVERSAL::isa( $core, 'SReln' ) ? 'relation'
                : UNIVERSAL::isa( $core, 'SRuleApp' ) ? 'ruleapp'
                :                                       confess "Strange core $core";
            my $rule = ( $type_of_core eq 'relation' ) ? createRule($core) : $core->get_rule();
            return ( $type_of_core, $rule );
        }

    }
};

CodeletFamily DoTheAsking( $core !, $exception !, $msg_prefix = {""} ) does {
INITIAL: { use Class::Multimethods qw{createRule}; }
RUN: {
        my ( $type_of_core, $rule ) = SCF::MaybeAskTheseTerms::get_core_type_and_rule($core);
        my $success;
        if ( $type_of_core eq 'relation' ) {
            $success = $exception->AskBasedOnRelation( $core, $msg_prefix );
        }
        else {
            $success = $exception->AskBasedOnRuleApp( $core, $msg_prefix );
        }

        if ($success) {
            RulesAskedSoFar::AddRuleToSuccessList($rule);
        }
        else {
            RulesAskedSoFar::AddRuleToFailureList($rule);
        }

    }
};
CodeletFamily MaybeAskUsingThisGoodRule( $core !, $rule !, $exception ! ) does {
RUN: {
        CODELET 10000, DoTheAsking,
            {
            core       => $core,
            exception  => $exception,
            msg_prefix => "I know I have asked this before...",
            };
    }
}

CodeletFamily MaybeAskUsingThisUnlikelyRule( $core !, $rule !, $exception ! ) does {
RUN: {

    }
}

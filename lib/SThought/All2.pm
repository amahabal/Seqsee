CodeletFamily AreWeDone( $group ! ) does {
NAME: {Am I Near the Solution?}
RUN: {
        my $gp          = $group;
        my $span        = $gp->get_span;
        my $total_count = $SWorkspace::ElementCount;
        my $left_edge   = $gp->get_left_edge();
        ## $span, $total_count
        #main::message( $right_extendibility);

        my $underlying_rule_app = $gp->get_underlying_reln();

        if ( $span / $total_count > 0.5 ) {
            Global::SetRuleAppAsRecent($underlying_rule_app) if $underlying_rule_app;
        }

        if ( $Global::AtLeastOneUserVerification
            and ( $span / $total_count ) > 0.8 )
        {
            if ( $left_edge == 0 ) {
                if ( $span == $total_count ) {

                    #Bingo!
                    Global::ClearHilit();
                    Global::Hilit( 2, @$gp );
                    main::update_display();
                    BelieveDone($group);
                }
                else {
                    ACTION 80, AttemptExtensionOfGroup,
                        {
                        object    => $gp,
                        direction => DIR::RIGHT()
                        };
                }
            }
        }

    }
FINAL: {
        my $LastSolutionDescriptionTime;

        sub BelieveDone {
            my ($group) = @_;
            if ($Global::TestingMode) {

                # Currently assume belief always right.
                SErr::FinishedTest->new( got_it => 1 )->throw();
            }
            return
                if ($LastSolutionDescriptionTime
                and $LastSolutionDescriptionTime > $Global::TimeOfLastNewElement );

            $LastSolutionDescriptionTime = $Global::Steps_Finished;
            main::message( "I believe I got it", 1 );
            ACTION 100, DescribeSolution, { group => $group };
        }

    }
}

1;

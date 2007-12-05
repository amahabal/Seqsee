CodeletFamily AreRelated( $a !, $b ! ) does {
RUN: {
        my $a_core = $a->can('get_core') ? $a->get_core() : undef;
        my $b_core = $b->can('get_core') ? $b->get_core() : undef;

        ## $a_core, $b_core

        if ( $a_core and $b_core ) {
            if ( $a_core->isa("SObject") and $b_core->isa("SObject") ) {
                ACTION 100, FindIfRelated,
                    {
                    a => $a_core,
                    b => $b_core
                    };
            }
            elsif ( $a_core->isa("SReln") and $b_core->isa("SReln") ) {
                ## I am comparing two relations!
                ACTION 100, FindIfRelatedRelns,
                    {
                    a => $a_core,
                    b => $b_core
                    };
            }
        }
    }
}

CodeletFamily AreTheseGroupable( $items !, $reln ! ) does {
RUN: {

        # Check if these are already grouped...
        # to do that, we need to find the left and right edges
        my ( @left_edges, @right_edges );
        for (@$items) {
            push @left_edges,  $_->get_left_edge;
            push @right_edges, $_->get_right_edge;
        }
        my $left_edge  = List::Util::min(@left_edges);
        my $right_edge = List::Util::max(@right_edges);
        my $is_covering
            = scalar( SWorkspace::__GetObjectsWithEndsBeyond( $left_edge, $right_edge ) );
        return if $is_covering;

        my $new_group;
        eval {
            my @unstarred_items = map { $_->GetUnstarred() } @$items;
            ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
            SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
            $new_group = SAnchored->create(@unstarred_items);
            if ($new_group) {
                $new_group->set_underlying_reln($reln);

                # next line commented on 07/1/06. Do I need reln_based?
                #return unless $new_group->describe_as($S::RELN_BASED);
                SWorkspace->add_group($new_group);
            }

        };
        if ( my $e = $EVAL_ERROR ) {
            if ( UNIVERSAL::isa( $e, "SErr::HolesHere" ) ) {
                return;
            }
            elsif ( UNIVERSAL::isa( $e, 'SErr::ConflictingGroups' ) ) {
                return;
            }
            print "HERE IN SCF::AreTheseGroupable, error is $e of type ", ref($e), "\n";
            confess $e;
        }

        # confess "@SWorkspace::OBJECTS New group created: $new_group, and added it to w/s";

    }
}

ThoughtType AreWeDone( $group ! ) does {
ACTIONS: {
        my $gp          = $group;
        my $span        = $gp->get_span;
        my $total_count = $SWorkspace::ElementCount;
        my $left_edge   = $gp->get_left_edge();
        ### $span, $total_count
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

CodeletFamily ShouldIFlip( $reln ! ) does {
RUN: {
        return unless $Global::Feature{AllowLeftwardRelations};

        #if this is part of a group, the answer is NO, don't flip!
        my ( $l, $r ) = $reln->get_extent();
        if ( SWorkspace::__GetObjectsWithEndsBeyond( $l, $r ) ) {
            return;
        }
        else {

            #okay, so we *may* switch... lets go ahead for now
            CODELET 100, flipReln, { reln => $reln };
        }

    }
}

1;

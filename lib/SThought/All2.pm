ThoughtType AreRelated( $a !, $b ! ) does {
ACTIONS: {
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

ThoughtType SAnchored( $core ! ) does {
AS_TEXT: { return "Group " . $self->get_core()->get_structure_string }
INITIAL: {
        multimethod get_fringe_for => ('SAnchored') => sub {
            my ($core) = @_;
            my @ret;

            my $structure = $core->get_structure();
            FRINGE 100, $S::LITERAL->build( { structure => $structure } );

            if ( my $rel = $core->get_underlying_reln() ) {
                FRINGE 50, $rel;
            }

            for my $category ( @{ $core->get_categories() } ) {
                next if $category eq $S::RELN_BASED;
                SLTM::SpikeBy( 5, $category );
                FRINGE 100, $category;

                my $bindings  = $core->GetBindingForCategory($category);
                my $meto_mode = $bindings->get_metonymy_mode();
                if ( $meto_mode ne $METO_MODE::NONE ) {
                    FRINGE 100, $meto_mode;
                    FRINGE 100, $bindings->get_metonymy_type();
                }
            }

            return \@ret;
        };
    }
FRINGE: {
        return get_fringe_for( $core->GetEffectiveObject() );
    }

ACTIONS: {
        SLTM::SpikeBy( 10, $core ) if $Global::Feature{LTM};

        my $metonym            = $core->get_metonym();
        my $metonym_activeness = $core->get_metonym_activeness();
        my $strength           = $core->get_strength();
        my $flush_right        = $core->IsFlushRight();
        my $flush_left         = $core->IsFlushLeft();
        my $span_fraction      = $core->get_span() / $SWorkspace::ElementCount;

        # extendibility checking...
        #if ( $flush_right and not($flush_left) ) {
        #    next unless SUtil::toss(0.15);
        #}
        CODELET 100, AttemptExtensionOfGroup,
            {
            object    => $core,
            direction => DIR::RIGHT(),
            };

        CODELET 50, AttemptExtensionOfGroup,
            {
            object    => $core,
            direction => DIR::LEFT(),
            };

        if ( $Global::Feature{Metonyms} and scalar(@$core) > 1 and SUtil::toss(0.8) ) {
            if ( SUtil::toss(0.5) ) {

                #main::message("Will launch ConvulseEnd");
                CODELET 50, ConvulseEnd,
                    {
                    object    => $core,
                    direction => $DIR::RIGHT,
                    };
            }
            else {

                #main::message("Will launch ConvulseEnd");
                CODELET 50, ConvulseEnd,
                    {
                    object    => $core,
                    direction => $DIR::LEFT,
                    };
            }
        }

        if ( $Global::Feature{LiteralCat} ) {
            CODELET 100, SetLiteralCat, { object => $core };
        }

        if ( $Global::Feature{LTM} ) {

            # Spread activation from corresponding node:
            SLTM::SpreadActivationFrom( SLTM::GetMemoryIndex($core) );
            my @active_followers = SLTM::FindActiveFollowers( $core, 0.01 );
            if (@active_followers) {
                for (@active_followers) {
                    main::debug_message(
                        $_->as_text()
                            . " appears to be a promising follower of "
                            . $core->as_text(),
                        1, 1
                    );
                }
            }
        }

        my $poss_cat;
        $poss_cat = $core->get_underlying_reln()->suggest_cat()
            if $core->get_underlying_reln;
        if ($poss_cat) {
            my $is_inst = $core->is_of_category_p($poss_cat);

            # main::message("$core is of $poss_cat? '$is_inst'");
            unless ($is_inst) {    #XXX if it already known, skip!
                CODELET 500, CheckIfInstance,
                    {
                    obj => $core,
                    cat => $poss_cat
                    };
            }

        }

        my $possible_category_for_ends = $core->get_underlying_reln()->suggest_cat_for_ends()
            if $core->get_underlying_reln;
        if ($possible_category_for_ends) {
            for ( @{ $core->get_underlying_reln()->get_items() } ) {
                unless ( UNIVERSAL::isa( $_, "SAnchored" ) ) {
                    print "An item of an SAnchored object($core) is not anchored!\n";
                    print "The anchored object is ", $core->get_structure_string(), "\n";
                    print "Its items are: ", join( "; ", @$core );
                    print "Items of the underlying ruleapp are: ",
                        join( "; ", @{ $core->get_underlying_reln()->get_items() } );
                    confess "$_ is not anchored!";
                }
                my $is_inst = $_->is_of_category_p($possible_category_for_ends);
                unless ($is_inst) {
                    CODELET 100, CheckIfInstance,
                        {
                        obj => $_,
                        cat => $possible_category_for_ends
                        };
                }
            }
        }

        if ( $span_fraction > 0.5 ) {
            THOUGHT LargeGroup, { group => $core };
        }

    }
}

ThoughtType SElement( $core !, $magnitude = {0} ) does {
AS_TEXT: { return "Element (" . $self->get_magnitude . ")"}
INITIAL: {

        multimethod get_fringe_for => ('SElement') => sub {
            my ($core) = @_;
            my $mag = $core->get_mag();
            my @ret;

            FRINGE 100, $S::LITERAL->build( { structure => [$mag] } );

            for ( @{ $core->get_categories() } ) {
                next if $_ eq $S::RELN_BASED;
                FRINGE 80, $_;
            }

            FRINGE 30, $S::LITERAL->build( { structure => [ $mag + 1 ] } );
            FRINGE 30, $S::LITERAL->build( { structure => [ $mag - 1 ] } );

            my $pos     = $core->get_left_edge();
            my $abs_pos = "absolute_position_" . $pos;
            FRINGE 80, $abs_pos;
            my $prev_abs_pos = "absolute_position_" . ( $pos - 1 );
            my $next_abs_pos = "absolute_position_" . ( $pos + 1 );
            FRINGE 30, $prev_abs_pos;
            FRINGE 30, $next_abs_pos;
            return \@ret;
        };

    }
ACTIONS: {
        SLTM::SpikeBy( 10, $core ) if $Global::Feature{LTM};

        #my $index = SLTM::GetMemoryIndex($core);
        #my ($activation) = @{SLTM::GetRealActivationsForIndices([$index])};
        #main::message("[$index] $core spiked: $activation!");
    }

FRINGE: {
        return get_fringe_for($core);
    }
BUILD: {
        $magnitude_of{$id} = $core->get_mag();
    }
}

ThoughtType SReln_Compound(
    $core !,
    $base_cat            = {0},
    $base_meto_mode      = {0},
    $base_pos_mode       = {0},
    $changed_bindings_of = {0},
    $metonymy_reln       = {0}
    ) does {
INITIAL: {
        multimethod 'createRule';
    }
FRINGE: {
        FRINGE 100, $base_cat;
        FRINGE 50,  $core->get_first();
        FRINGE 50,  $core->get_second();
    }
BUILD: {
        $base_cat_of{$id}            = $core->get_base_category;
        $base_meto_mode_of{$id}      = $core->get_base_meto_mode;
        $base_pos_mode_of{$id}       = $core->get_base_pos_mode;
        $changed_bindings_of_of{$id} = $core->get_changed_bindings_ref;
        $metonymy_reln_of{$id}       = $core->get_metonymy_reln;

    }
ACTIONS: {
        my $holey = SWorkspace->are_there_holes_here( $core->get_ends );

        if ( $core->get_type()->IsEffectivelyASamenessRelation() ) {
            CODELET 100, AreTheseGroupable,
                {
                items => [ $core->get_ends ],
                reln  => $core,
                };
        }

        #if ( not $holey ) {
        ACTION 80, AttemptExtensionOfRelation, { core => $core, direction => $DIR::RIGHT };
        ACTION 80, AttemptExtensionOfRelation, { core => $core, direction => $DIR::LEFT };

        SLTM::InsertFollowsLink( $core->get_ends(), $core )->Spike(5) if $Global::Feature{LTM};

        #}

        {
            my $relntype = $core->get_type();
            my $activation = SLTM::SpikeBy( 5, $relntype );
            if ( SUtil::toss($activation) ) {

                # XXX(Board-it-up): [2007/01/01] should check if rule rejected...
                my $rule              = createRule($core);
                my $has_been_rejected = $rule->has_been_rejected();
                if ( !$has_been_rejected
                    or SUtil::toss( 1 - 10 / $has_been_rejected ) )
                {

                    #ACTION 100, TryRule,
                    #  {
                    #    rule => $rule,
                    #    reln => $core,
                    # };
                }
            }

        }

        {
            last unless $holey;
            my ( $l1, $r1, $l2, $r2 ) =
                map { $_->get_edges() } ( $core->get_first(), $core->get_second() );
            my @gap                 = ( min( $r1, $r2 ) + 1, max( $l1, $l2 ) - 1 );
            my @intervening_objects = SWorkspace->get_intervening_objects(@gap);
            my $distance            = scalar(@intervening_objects);
            last unless $distance;

            my $possible_ad_hoc_cat = $S::AD_HOC->build( { parts_count => $distance + 1 } );

            #main::message(Scalar::Util::refaddr($possible_ad_hoc_cat));
            SLTM::InsertUnlessPresent($possible_ad_hoc_cat);
            my $ad_hoc_activation = SLTM::SpikeBy( 5 / $distance, $possible_ad_hoc_cat );

            #main::message("ad_hoc(dis => $distance) activation: $ad_hoc_activation");

            if (    SUtil::significant($ad_hoc_activation)
                and SUtil::toss($ad_hoc_activation) )
            {
                my @ends =
                    sort { $a->get_left_edge() <=> $b->get_left_edge() } ( $core->get_ends() );

# XXX(Board-it-up): [2006/11/16] Mysteriously, the next line fails.
#            my @ends = ikeysort { $_->get_left_edge() } ( $core->get_first(), $core->get_second() );
                my $new_obj = SAnchored->create( $ends[0], @intervening_objects );
                if ( SWorkspace::__GetObjectsWithEndsExactly( $new_obj->get_edges() ) ) {
                    return;
                }

                SWorkspace->add_group($new_obj) or return;
                $new_obj->describe_as($possible_ad_hoc_cat);
            }

        }

    }
}

ThoughtType SReln_Simple( $core !, $str = {0} ) does {
INITIAL: {
        multimethod 'createRule';
    }
FRINGE: {
        FRINGE 100, $str;
        FRINGE 50,  $core->get_first();
        FRINGE 50,  $core->get_second();
    }
BUILD: {
        $str_of{$id} = $core->get_text();
    }
ACTIONS: {
        my $holey = SWorkspace->are_there_holes_here( $core->get_ends );

        if ( $str eq "same" ) {
            CODELET 100, AreTheseGroupable,
                {
                items => [ $core->get_first(), $core->get_second(), ],
                reln  => $core,
                };
        }
        elsif ( not( SWorkspace::__GetObjectsWithEndsBeyond( $core->get_extent() ) ) ) {
            CODELET 100, AreTheseGroupable,
                {
                items => [ $core->get_first(), $core->get_second(), ],
                reln  => $core,
                };
        }

        {

            # last if $holey;
            CODELET 100, AttemptExtensionOfRelation,
                {
                core      => $core,
                direction => DIR::RIGHT()
                };
            SLTM::InsertFollowsLink( $core->get_ends(), $core )->Spike(5) if $Global::Feature{LTM};
        }

        {
            my $relntype = $core->get_type();
            my $activation = SLTM::SpikeBy( 5, $relntype );
            if ( SUtil::toss($activation) ) {

                # XXX(Board-it-up): [2007/01/01] should check if rule rejected...
                my $rule              = createRule($core);
                my $has_been_rejected = $rule->has_been_rejected();
                if ( !$has_been_rejected
                    or SUtil::toss( 1 - 10 / $has_been_rejected ) )
                {

                    # XXX(Board-it-up): [2007/02/04] buggy TryRule... don't use without fixing
                    # creates objects using starred versions...
                    #ACTION 100, TryRule,
                    #  {
                    #    rule => $rule,
                    #    reln => $core,
                    #  };
                }
            }

        }

        {
            last unless $holey;
            my ( $l1, $r1, $l2, $r2 ) =
                map { $_->get_edges() } ( $core->get_first(), $core->get_second() );
            my @gap = ( min( $r1, $r2 ) + 1, max( $l1, $l2 ) - 1 );
            if ( $gap[1] >= $SWorkspace::ElementCount ) {
                print STDERR "Ends: ($l1, $r1), ($l2, $r2)\n";
                print STDERR "Second is: ", $core->get_second(), "with structure ",
                    $core->get_second()->get_structure_string(), "\n";
                print STDERR "Element count: $SWorkspace::ElementCount\n";
                print STDERR "Gap: @gap\n";
                my $elements = join( ", ", map { $_->get_mag } SWorkspace::GetElements() );
                print STDERR "Elements: $elements\n";
                print STDERR map { $_->get_structure_string() } $core->get_ends();
                print STDERR "\nHistory of core: \n\t", join( "\n\t", @{ $core->get_history() } ),
                    "\n";
                print STDERR "\nHistory of first: \n\t",
                    join( "\n\t", @{ $core->get_first()->get_history() } ), "\n";
                print STDERR "\nHistory of second: \n\t",
                    join( "\n\t", @{ $core->get_second()->get_history() } ), "\n";
            }
            my @intervening_objects = SWorkspace->get_intervening_objects(@gap);
            my $distance            = scalar(@intervening_objects);
            last unless $distance;

            my $possible_ad_hoc_cat = $S::AD_HOC->build( { parts_count => $distance + 1 } );

            #main::message(Scalar::Util::refaddr($possible_ad_hoc_cat));
            SLTM::InsertUnlessPresent($possible_ad_hoc_cat);
            my $ad_hoc_activation = SLTM::SpikeBy( 20 / $distance, $possible_ad_hoc_cat );

            #main::message("ad_hoc(dis => $distance) activation: $ad_hoc_activation");

            if (    SUtil::significant($ad_hoc_activation)
                and SUtil::toss($ad_hoc_activation) )
            {
                my @ends = SWorkspace::__SortLtoRByLeftEdge( $core->get_first()->GetUnstarred(),
                    $core->get_second()->GetUnstarred() );
                my $new_obj = SAnchored->create( $ends[0], @intervening_objects );
                if ( SWorkspace::__GetObjectsWithEndsExactly( $new_obj->get_edges() ) ) {
                    return;
                }

                SWorkspace->add_group($new_obj);
                $new_obj->describe_as($possible_ad_hoc_cat);
            }

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

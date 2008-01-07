ThoughtType SAnchored( $core ! ) does {
AS_TEXT: { return "Group " . $self->get_core()->get_structure_string }
INITIAL: {
        multimethod get_fringe_for => ('SAnchored') => sub {
            my ($core) = @_;
            my @ret;

            my $structure = $core->get_structure();
            my $literal_cat = SCat::OfObj::Literal->Create($structure);
            FRINGE 100, $literal_cat;

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
        
        sub StrengthenLink {
            my ( $o1, $o2 ) = @_;
            my $relation = $o1->get_relation($o2) || return;
            my $category = $relation->isa('SReln::Simple') ? $S::NUMBER : $relation->get_base_category();
            SLTM::InsertISALink($o1, $category)->Spike(10);
            SLTM::InsertISALink($o2, $category)->Spike(10);
            SLTM::InsertFollowsLink($category, $relation)->Spike(15);
        };

        sub ExtendFromMemory {
            my ( $core ) = @_;
            my $flush_right        = $core->IsFlushRight();
            if ($flush_right and $SWorkspace::ElementCount <= 3) {
                my $weighted_set = SLTM::FindActiveFollowers( $core );
                return unless $weighted_set->is_not_empty();
                
                my $chosen_follower = $weighted_set->choose();
                my $exception = SErr::ElementsBeyondKnownSought->new(next_elements => $chosen_follower->get_flattened());
                $exception->Ask();
            } elsif ($Global::Feature{LTM_expt}) {
                my $weighted_set = SLTM::FindActiveFollowers( $core );
                return unless $weighted_set->is_not_empty();
                
                my $chosen_follower = $weighted_set->choose();
                my $next = SWorkspace->GetSomethingLike({object => $chosen_follower,
                                                         start => $core->get_right_edge() + 1,
                                                         direction => $DIR::RIGHT,
                                                         trust_level => 50,
                                                     }) || return;
                CODELET 100, FindIfRelated, {a => $core, b=>$next};
            }
        };
        sub AddCategoriesFromMemory {
            my ( $core ) = @_;
            my $weighted_set = SLTM::FindActiveCategories($core);
            $weighted_set->delete_below_threshold(0.3);
            if ($weighted_set->is_not_empty()) {
                my $category = $weighted_set->choose();
                CODELET 100, CheckIfInstance, { obj => $core, cat => $category};
            }
        }
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
        my $underlying_reln    = $core->get_underlying_reln();
        my $parts_count        = scalar(@$core);

        # extendibility checking...
        #if ( $flush_right and not($flush_left) ) {
        #    next unless SUtil::toss(0.15);
        #}
        CODELET 50, AttemptExtensionOfGroup,
            {
            object    => $core,
            direction => DIR::RIGHT(),
            };

        if ( $core->get_left_edge() > 0 ) {
            CODELET 100, AttemptExtensionOfGroup,
                {
                object    => $core,
                direction => DIR::LEFT(),
                };
        }

        if ( scalar(@$core) > 1 and SUtil::toss(0.8) ) {
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
            ExtendFromMemory($core);

            AddCategoriesFromMemory($core);
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
            CODELET 100, LargeGroup, { group => $core };
        }
        
        if ($Global::Feature{LTM}) {
            if ($parts_count >= 3) {
                for (0..$parts_count-2) {
                    StrengthenLink($core->[$_], $core->[$_+1]);
                }
            }
        }
    }
}

ThoughtType SElement( $core !, $magnitude = {0} ) does {
AS_TEXT: { return "Element (" . $self->get_magnitude . ")" }
INITIAL: {

        multimethod get_fringe_for => ('SElement') => sub {
            my ($core) = @_;
            my $mag = $core->get_mag();
            my @ret;


            for ( @{ $core->get_categories() } ) {
                next if $_ eq $S::RELN_BASED;
                FRINGE 80, $_;
            }

            my @literal_cats = map { SCat::OfObj::Literal->Create([$mag+$_])} (0, 1, -1);
            FRINGE 100, $literal_cats[0];
            FRINGE 30, $literal_cats[1];
            FRINGE 30, $literal_cats[-1];

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

        if ( $Global::Feature{LTM} ) {
            # Spread activation from corresponding node:
            SLTM::SpreadActivationFrom( SLTM::GetMemoryIndex($core) );
            SThought::SAnchored::ExtendFromMemory($core);

            SThought::SAnchored::AddCategoriesFromMemory($core);
        }

    }

FRINGE: {
        return get_fringe_for($core);
    }
BUILD: {
        $magnitude_of{$id} = $core->get_mag();
    }
}
1;

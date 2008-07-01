CodeletFamily FocusOn( $what = {0} ) does {
NAME: { Read from Workspace }
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
        main::message("Focusing on: ".$object->as_text()) if $Global::debugMAX;
        ContinueWith( SThought->create($object) );
    }
};

CodeletFamily LookForSimilarGroups( $group ! ) does {
NAME: { Look for Similar Groups }
RUN: {
        my $wset = SWorkspace::__GetObjectsBelongingToSimilarCategories($group);
        return if $wset->is_empty();

        for ( $wset->choose_a_few_nonzero(3) ) {
            CODELET 50, FocusOn, { what => $_ };
        }
    }
};

CodeletFamily MergeGroups( $a !, $b ! ) does {
NAME: { Merge Groups }
RUN: {
        return if $a eq $b;
        SWorkspace::__CheckLiveness($a, $b) or return;
        my @items = SUtil::uniq(@$a, @$b);
        @items = SWorkspace::__SortLtoRByLeftEdge(@items);

        return if SWorkspace::__AreThereHolesOrOverlap(@items);
        my $new_group;
        TRY {
            my @unstarred_items = map { $_->GetUnstarred() } @items;
            ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
            SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
            $new_group = SAnchored->create(@unstarred_items);
            if ($new_group and $a->get_underlying_reln()) {
                $new_group->set_underlying_ruleapp($a->get_underlying_reln()->get_rule());
                $a->CopyCategoriesTo($new_group);
                SWorkspace->add_group($new_group);
            }
        } CATCH {
          ConflictingGroups: { return }
        }

    }
}

CodeletFamily CleanUpGroup( $group ! ) does {
NAME: { Clean Up Group }
RUN: { 
        return unless SWorkspace::__CheckLiveness($group);
        my @edges = $group->get_edges();
        my @potential_cruft = SWorkspace::__GetObjectsWithEndsNotBeyond(@edges);
        SWorkspace::__DeleteNonSubgroupsOfFrom({ of => [$group],
                                                 from => \@potential_cruft,
                                             });
    }
}

CodeletFamily DoTheSameThing( $group = {0}, $category = {0}, $direction = {0}, $transform ! ) does {
INITIAL: { multimethod '__PlonkIntoPlace'; }
NAME: { Do The Same Thing }
RUN: {
        unless ( $group or $category ) {
            $category = $transform->get_category();
        }
        if ( $group and $category ) {
            confess "Need exactly one of group and category: got both.";
        }
        $direction ||= SChoose->choose( [ 1, 1 ], [ $DIR::LEFT, $DIR::RIGHT ] );
        unless ($group) {
            my @groups_of_cat = SWorkspace::__GetObjectsBelongingToCategory($category) or return;
            $group = SWorkspace::__ChooseByStrength( @groups_of_cat );
        }

        #main::message("DoTheSameThing: group=" . $group->as_text()." transform=".$transform->as_text());
        my $effective_transform
            = $direction eq $DIR::RIGHT ? $transform : $transform->FlippedVersion();
        $effective_transform or return;
        $effective_transform->CheckSanity() or confess "Transform insane!";

        my $expected_next_object = ApplyTransform( $effective_transform, $group ) or return;
        @$expected_next_object or return;

        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $group,
                direction   => $direction,
                distance    => DISTANCE::Zero(),
            }
        );
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $is_this_what_is_present;
        TRY {
            $is_this_what_is_present = SWorkspace->check_at_location(
                {   start     => $next_pos,
                    direction => $direction,
                    what      => $expected_next_object,
                }
            );
        }
        CATCH {
        ElementsBeyondKnownSought: {
              return;
            }
        };
        
        if ($is_this_what_is_present) {
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $expected_next_object );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->get_resultant_object() or return;

            $wso->describe_as($effective_transform->get_category());
            my @ends = ($direction eq $DIR::RIGHT) ? ($group, $wso) : ($wso, $group);
            SRelation->new({first=>$ends[0], second => $ends[1], type => $transform})->insert();
            #main::message("yeah, that was present!");
        }
    }
}

CodeletFamily CreateGroup( $items !, $category = {0}, $transform = {0} ) does {
NAME: { Create Group }
RUN: {
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

        unless ($category or $transform) {
            confess "At least one of category or transform needed. Got neither.";
        }
        if ($category and $transform) {
            confess "Exactly one of  category or transform needed. Got both.";
        }

        unless ($category) {
            # Generate from transform.
            confess "transform should be a Transform!" unless $transform->isa('Transform');
            if ($transform->isa('Transform::Numeric')) {
                $category = $transform->GetRelationBasedCategory();
            } else {
                $category = SCat::OfObj::RelationTypeBased->Create($transform);
            }
        }

        my @unstarred_items = map { $_->GetUnstarred() } @$items;
        ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
        SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
        my $new_group;
        TRY { $new_group = SAnchored->create(@unstarred_items); }
        CATCH {
        HolesHere: { return; }
        };
        return unless $new_group;
        $new_group->describe_as($category) or return;
        if ($transform) {
            $new_group->set_underlying_ruleapp($transform);
        }
        SWorkspace->add_group($new_group);
    }
}

CodeletFamily FindIfRelatedRelations( $a ! , $b ! ) does {
NAME: { Find if Analogies are Related }
RUN: {
        my ( $af, $as, $bf, $bs ) = ( $a->get_ends(), $b->get_ends() );
        if ($bs eq $af) {
            # Switch the two...
            ($af, $as, $a, $bf, $bs, $b) = ($bf, $bs, $b, $af, $as, $a);
        }

        return unless $as eq $bf;

        my ($a_transform, $b_transform) = ($a->get_type(), $b->get_type());
        if ($a_transform eq $b_transform) {
            CODELET 100, CreateGroup, { items => [$af, $as, $bs],
                                        transform => $a_transform,
                                    };
        } elsif ($Global::Feature{Alternating} and
            $a_transform->get_category() eq $b_transform->get_category()) {
            # There is a chance that these are somehow alternating...
            my $new_transform = SCat::OfObj::Alternating->CheckForAlternation(
                # $a_transform->get_category(),
                $af, $as, $bs);
            if ($new_transform) {
                CODELET 100, CreateGroup, { items => [$af, $as, $bs],
                                            transform => $new_transform,
                                        };
            }
        }
    }
}

CodeletFamily CheckIfAlternating( $first !, $second !, $third ! ) does {
NAME: { Check if Alternating }
RUN: { 
        my $transform_to_consider;

        my $t1 = FindTransform($first, $second);
        my $t2 = FindTransform($second, $third);
        if ($t1 and $t1 eq $t2) {
            $transform_to_consider = $t1;
        } else {
            $transform_to_consider = SCat::OfObj::Alternating->CheckForAlternation($first, $second, $third) or return;
        }
        CODELET 100, CreateGroup, { items => [$first, $second, $third],
                                    transform => $transform_to_consider,
                                };
    }
}

CodeletFamily FindIfRelated(   $a!, $b!) does {
  NAME: {Check Whether Analogous}
  RUN: {
        return unless SWorkspace::__CheckLiveness( $a, $b );
        ( $a, $b ) = SWorkspace::__SortLtoRByLeftEdge( $a, $b );
        if ( $a->overlaps($b) ) {
            my ( $ul_a, $ul_b ) = ( $a->get_underlying_reln(), $b->get_underlying_reln() );
            return unless ( $ul_a and $ul_b );
            return unless $ul_a->get_rule() eq $ul_b->get_rule();
            return unless ($a->[-1] ~~ @$b); #i.e., actual subgroups overlap.
            CODELET 200, MergeGroups, { a => $a, b => $b };
            return;
        }

        if (my $relation = $a->get_relation($b)) {
            SLTM::SpikeBy(10, $relation->get_type());
            CODELET 100, FocusOn, { what => $relation };
            return;
        }

        my $reln_type = FindTransform($a, $b) || return;
        SLTM::SpikeBy(10, $reln_type);
        
        # insert relation with certain probability:
        my $transform_complexity = $reln_type->get_complexity();
        my $transform_activation = SLTM::GetRealActivationsForOneConcept($reln_type);
        my $distance = SWorkspace::__FindDistance($a, $b, $DISTANCE_MODE::ELEMENT)->GetMagnitude();
        my $sense_in_continuing = ShouldIContinue($transform_complexity,
                                                  $transform_activation,
                                                  $distance
                                                      );
        main::message("Sense in continuing=$sense_in_continuing") if $Global::debugMAX;
        return unless SUtil::toss($sense_in_continuing);

        SLTM::SpikeBy(10, $reln_type);
        my $relation = SRelation->new({first => $a,
                                       second => $b,
                                       type => $reln_type
                                           });
        $relation->insert();
        CODELET 200, FocusOn, { what => $relation };
    }
  FINAL: {
        sub ShouldIContinue {
            my ( $transform_complexity, $transform_activation, $distance ) = @_;
            # transform_activation and transform_complexity are between 0 and 1

            my $not_continue = $transform_complexity * (1 - $transform_activation)
                * sqrt($distance);
            return 1 - $not_continue;
        }
    }
}

CodeletFamily AttemptExtensionOfRelation( $core !, $direction ! ) does {
NAME: { Attempt Extension of Analogy }
INITIAL: { multimethod '__PlonkIntoPlace'; }
RUN: { 
        my $transform = $core->get_type();
        my ($end1, $end2) = $core->get_ends();

        my ($effective_transform, $object_at_end);
        given ($direction) {
            when ($DIR::RIGHT) {
                ($effective_transform, $object_at_end) = ($transform, $end2);
            }
            when ($DIR::LEFT) {
                $effective_transform = $transform->FlippedVersion() or return;
                $object_at_end = $end1;
            }
        }

        my $distance = SWorkspace::__FindDistance( $end1, $end2 );
        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $object_at_end,
                direction   => $direction,
                distance    => $distance,
            }
        );
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $what_next = ApplyTransform( $effective_transform,
                                        $object_at_end->GetEffectiveObject() );
        return unless $what_next;
        return unless @$what_next;    # 0 elts also not okay

        my $is_this_what_is_present;
        TRY {
            $is_this_what_is_present = SWorkspace->check_at_location(
                {   start     => $next_pos,
                    direction => $direction,
                    what      => $what_next
                }
            );
        }
        CATCH {
        ElementsBeyondKnownSought: {
              return unless EstimateAskability($core, $transform, $end1, $end2);
              CODELET 100, AskIfThisIsTheContinuation, {
                  relation  => $core,
                  exception => $err,
                  expected_object => $what_next,
                  start_position => $next_pos,
                  known_term_count => $SWorkspace::ElementCount,
                      };
            }
      };

        if ($is_this_what_is_present) {
            SLTM::SpikeBy(10, $transform);
            
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $what_next );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->get_resultant_object();

            my $cat = $transform->get_category();
            SLTM::SpikeBy(10, $cat);
            $wso->describe_as($cat) or return;

            my $reln_to_add;
            given ($direction) {
                when ($DIR::RIGHT) { 
                    $reln_to_add = SRelation->new({first => $end2,
                                                   second => $wso,
                                                   type => $transform,
                                               });
                }
                when ($DIR::LEFT) {
                    $reln_to_add = SRelation->new({first => $wso,
                                                   second => $end1,
                                                   type => $transform,
                                               });
                }
            }
            $reln_to_add->insert() if $reln_to_add;
        }
    }
  FINAL: {
        sub EstimateAskability {
            my ( $relation, $transform, $end1, $end2 ) = @_;
            if (SWorkspace->AreThereAnySuperSuperGroups($end1) or
                    SWorkspace->AreThereAnySuperSuperGroups($end2)
                    ) {
                return 0;
            }

            my $supergroup_penalty = 0;
            if (SWorkspace->GetSuperGroups($end1) or SWorkspace->GetSuperGroups($end2)) {
                $supergroup_penalty = 0.6;
            }

            my $transform_activation = SLTM::GetRealActivationsForOneConcept($transform);
            return SUtil::toss($transform_activation * ( 1 - $supergroup_penalty ));
        }
    }
}

CodeletFamily AttemptExtensionOfGroup_proposed(   $object!, $direction!) does {
  NAME: {Attempt Extension of Group}
  INITIAL: { multimethod '__PlonkIntoPlace'; }
  RUN: {
        SWorkspace::__CheckLiveness($object) or return;
        my $underlying_reln = $object->get_underlying_reln() or return;
        my $transform = $underlying_reln->get_rule()->get_transform();

        my ($next_position, $expected_next_object);
        given ($direction) {
            when ($DIR::RIGHT) {
                $expected_next_object = ApplyTransform($transform, $object->[-1]) or return;
                $next_position = $object->get_right_edge() + 1;
            }
            when ($DIR::LEFT) {
                my $effective_transform = $transform->FlippedVersion() or return;
                $expected_next_object = ApplyTransform($effective_transform, $object->[0]);
                $next_position = $object->get_left_edge() - 1;
                return if $next_position == -1;
            }
        }

        my $result_of_something_like =
            SWorkspace->LookForSomethingLike({
                object => $expected_next_object,
                start_position => $next_position,
                direction => $direction,
                    });

        if (my $to_ask = $result_of_something_like->get_to_ask()) {
            if (EstimateAskability($object)) {
                CODELET 100, AskIfThisIsTheContinuation, {
                    %$to_ask,
                    group => $object,
                    known_term_count => $SWorkspace::ElementCount,
                        };
                return;
            }
        }
        if ($Global::Feature{AllowSquinting}) {
            confess "IMPLEMENT ME!";
        } else {
            my $literally_present = $result_of_something_like->get_literally_present() or return;
            my $plonk_result = __PlonkIntoPlace(@$literally_present);
            my $new_object = $plonk_result->get_resultant_object() or return;

            given ($direction) {
                when ($DIR::RIGHT) {
                    # main::message("In AttemptExtensionOfGroup: $object->[-1] and $new_object and $transform");
                    my $new_relation = SRelation->new({first => $object->[-1],
                                                       second => $new_object, 
                                                       type => $transform,
                                                   });
                    $new_relation->insert() or return;
                    $object->Extend($new_object, 1);
                }
                when ($DIR::LEFT) {
                    my $effective_transform = $transform->FlippedVersion() or return;
                    my $new_relation = SRelation->new({first => $new_object,
                                                       second => $object->[0], 
                                                       type => $effective_transform,
                                                   });
                    $new_relation->insert() or return;
                    $object->Extend($new_object, 0);
                }
            }
        }
    }
    FINAL: {
          sub EstimateAskability {
              my ( $group ) = @_;
              
          }
      }
}

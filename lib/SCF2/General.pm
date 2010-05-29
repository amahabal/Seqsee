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

        my $reln_type = FindMapping($a, $b) || return;
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
INITIAL: { multimethod '__PlonkIntoPlace'; multimethod 'SanityCheck'; }
RUN: { 
        ## Codelet started:
        my $transform = $core->get_type();
        my ($end1, $end2) = $core->get_ends();
        ## ends: $end1->as_text, $end2->as_text
        my ($effective_transform, $object_at_end);
        if ($direction eq $DIR::RIGHT) {
            ($effective_transform, $object_at_end) = ($transform, $end2);
            ## Thought it was right:
        } else {
            $effective_transform = $transform->FlippedVersion() or return;
            $object_at_end = $end1;        
        }

        my $distance = SWorkspace::__FindDistance( $end1, $end2 );
        ## oae_l: $object_at_end->get_left_edge(), $distance, $direction
        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $object_at_end,
                direction   => $direction,
                distance    => $distance,
            }
        );
        ## next_pos: $next_pos
        return unless defined($next_pos);
        ## distance, next_pos: $distance, $next_pos
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $what_next = ApplyMapping( $effective_transform,
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

        ## is_this_what_is_present:
        if ($is_this_what_is_present) {
            SLTM::SpikeBy(10, $transform);
            
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $what_next );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->resultant_object();

            my $cat = $transform->get_category();
            SLTM::SpikeBy(10, $cat);
            $wso->describe_as($cat) or return;

            my $reln_to_add;
            if ($direction eq $DIR::RIGHT) {
                    $reln_to_add = SRelation->new({first => $end2,
                                                   second => $wso,
                                                   type => $transform,
                                               });
                } else {
                    $reln_to_add = SRelation->new({first => $wso,
                                                   second => $end1,
                                                   type => $transform,
                                               });
               
                }
            $reln_to_add->insert() if $reln_to_add;
            ## HERE1:
            # SanityCheck($reln_to_add);
            ## Here2:
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
                $expected_next_object = ApplyMapping($transform, $object->[-1]) or return;
                $next_position = $object->get_right_edge() + 1;
            }
            when ($DIR::LEFT) {
                my $effective_transform = $transform->FlippedVersion() or return;
                $expected_next_object = ApplyMapping($effective_transform, $object->[0]);
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
            my $new_object = $plonk_result->resultant_object() or return;

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

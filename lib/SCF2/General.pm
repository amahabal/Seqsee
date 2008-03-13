CodeletFamily FocusOn( $what = {0} ) does {
NAME: { Focus On }
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
            state $strength_chooser = SChoose->create( { map => \&SFasc::get_strength } );
            $group = $strength_chooser->( \@groups_of_cat );
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
        my $new_group = SAnchored->create(@unstarred_items);
        $new_group->describe_as($category) or return;
        if ($transform) {
            $new_group->set_underlying_ruleapp($transform);
        }
        SWorkspace->add_group($new_group);
    }
}

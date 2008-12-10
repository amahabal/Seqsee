ThoughtType SRelation( $core ! ) does {
  NAME: {Focusing on an Analogy}
AS_TEXT: { return $self->get_core()->as_text }
INITIAL: {
        multimethod 'createRule';
    }
FRINGE: {
        FRINGE 100, $core->get_type();
        FRINGE 50,  $core->get_first();
        FRINGE 50,  $core->get_second();
    }
ACTIONS: {
        my ( $end1,        $end2 )         = $core->get_ends;
        my ( $extent_left, $extent_right ) = $core->get_extent;
        my $relntype                = $core->get_type();
        my $relationtype_activation = SLTM::SpikeBy( 5, $relntype );
        my $are_ends_contiguous = $core->are_ends_contiguous();

        if ( $are_ends_contiguous and $relntype->IsEffectivelyASamenessRelation() ) {
            CODELET 100, AreTheseGroupable,
                {
                items => [ $end1, $end2 ],
                reln  => $core,
                };
        }
        elsif ( $are_ends_contiguous and not SWorkspace::__GetObjectsWithEndsBeyond( $extent_left, $extent_right ) ) {
            CODELET 80, AreTheseGroupable,
                {
                items => [ $end1, $end2 ],
                reln  => $core,
                };
        }

        CODELET 100, AttemptExtensionOfRelation,
            {
            core      => $core,
            direction => DIR::RIGHT()
            };
        CODELET 100, AttemptExtensionOfRelation,
            {
            core      => $core,
            direction => DIR::LEFT()
            };
        # SLTM::InsertFollowsLink( $core->get_ends(), $core )->Spike(5) if $Global::Feature{LTM};

        my @ends = SWorkspace::__SortLtoRByLeftEdge( $end1, $end2 );
        my @intervening_objects
            = SWorkspace->get_intervening_objects( $ends[0]->get_right_edge + 1,
                                                   $ends[1]->get_left_edge - 1 );
        my $distance_magnitude = scalar(@intervening_objects);
        if ($distance_magnitude) {
            my $possible_ad_hoc_cat = SCat::OfObj::Interlaced->Create($distance_magnitude + 1);
            my $ad_hoc_activation = SLTM::SpikeBy( 20 / $distance_magnitude, $possible_ad_hoc_cat );
            if ( SUtil::significant($ad_hoc_activation) and SUtil::toss($ad_hoc_activation) ) {
                my @new_object_parts =
                    SUtil::toss(0.5)
                    ? ( $ends[0], @intervening_objects )
                    : ( @intervening_objects, $ends[1] );
                if (not SWorkspace::__GetObjectsWithEndsExactly(
                        $new_object_parts[0]->get_left_edge(),
                        $new_object_parts[-1]->get_right_edge()
                    )
                    )
                {
                    my $new_obj = SAnchored->create(@new_object_parts);
                    SWorkspace->add_group($new_obj);
                    $new_obj->describe_as($possible_ad_hoc_cat);
                }
            }
        }

    }
}

1;

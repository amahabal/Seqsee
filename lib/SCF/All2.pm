CodeletFamily CheckIfInstance( $obj !, $cat ! ) does {
RUN: {
        if ( $obj->describe_as($cat) ) {
            if ( $Global::Feature{LTM} ) {
                SLTM::SpikeBy( ««SpikeAmount, CheckIfInstance::Category»», $cat );
                SLTM::InsertISALink( $obj, $cat )->Spike(««SpikeAmount,
                                                           CheckIfInstance::Link »»);
            }
        }
    }
}

CodeletFamily SetLiteralCat( $object ! ) does {
RUN: {
        my @structure;
        if ( $object->get_metonym_activeness ) {
            @structure = $object->get_metonym()->get_starred->get_structure();
        }
        else {
            @structure =
                map { $_->get_structure }
                map { $_->GetEffectiveObject } @{ $object->get_parts_ref };
            ## @structure
        }

        my $lit_cat = SCat::OfObj::Literal->Create([@structure]);
## $lit_cat, ident $lit_cat
        my $bindings = $object->describe_as($lit_cat)
            or confess "Hey, should NEVER have failed!";
    }
}

CodeletFamily AttemptExtensionOfRelation( $core !, $direction ! ) does {
INITIAL: {
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';
        multimethod '__PlonkIntoPlace';
    }
RUN: {
        my $direction_of_core = $core->get_direction;
        return unless $direction_of_core->IsLeftOrRight;

        my ( $relation_to_consider, $obj1, $obj2 );
        if ( $direction eq $direction_of_core ) {
            ( $relation_to_consider, $obj1, $obj2 ) = ( $core->get_type(), $core->get_ends );
        }
        else {
            $relation_to_consider = $core->get_type()->FlippedVersion() or return;
            $relation_to_consider->CheckSanity() or confess "Flip failed!";
            ( $obj2, $obj1 ) = $core->get_ends;
        }

        my $distance = SWorkspace::__FindDistance( $obj1, $obj2 );
        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $obj2,
                direction   => $direction,
                distance    => $distance,
            }
        );
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $what_next = ApplyTransform( $relation_to_consider, $obj2->GetEffectiveObject() );
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
                return unless EstimateAskability($core);

                #  Global::Hilit( 1, $obj1, $obj2, $core );
                #  my $reply = $err->Ask();
                #  Global::ClearHilit();
                #  return unless $reply;
                #  $is_this_what_is_present = 1;
                CODELET ««Urgencies, AttemptExtensionOfRelation::MaybeAsk»», MaybeAskTheseTerms, { core => $core, exception => $err };
                return;
            }
        };
        if ($is_this_what_is_present) {
            SLTM::SpikeBy( ««SpikeAmount, AttemptExtensionOfRelation::Core»», $core );
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $what_next );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->get_resultant_object();

            if ( $core->isa('Transform::Structural') ) {
                my $type = $core->get_base_category;
                SLTM::SpikeBy( ««SpikeAmount , AttemptExtensionOfRelation::CoreCategory »», $type );
                ## Describe as: $type
                $wso->describe_as($type) or return;
            }
            my $reln_to_add;
            if ( $direction eq $direction_of_core ) {
                my $transform = FindTransform($obj2, $wso);
                $reln_to_add = SRelation->new({first => $obj2, second => $wso,
                                               type => $transform
                                           });
            }
            else {
                my $transform = FindTransform($wso, $obj2);
                $reln_to_add = SRelation->new({first => $wso, second => $obj2,
                                               type => $transform
                                           });
            }
            $reln_to_add->insert() if $reln_to_add;
        }
        else {

            # Weaken relation a bit.
            SLTM::WeakenBy( ««WeakenAmount , AttemptExtensionOfRelation::Core »», $core );

            # Weaken corresponding ad-hoc if this was one.
            if ( $distance > 1 ) {
                my $possible_ad_hoc_cat = SCat::OfObj::Interlaced->Create($distance->GetMagnitude() + 1);
                SLTM::WeakenBy( ««WeakenAmount , AttemptExtensionOfRelation::AdHocOnFail»», $possible_ad_hoc_cat );
            }

            if ( SUtil::toss(0.5) ) {
                CODELET ««Urgencies , AttemptExtensionOfRelation::AreTheseGroupable »», AreTheseGroupable,
                    {
                    items => [ $core->get_ends() ],
                    reln  => $core
                    };
            }
        }
    }
FINAL: {

        sub EstimateAskability {
            my ($core) = @_;
            SLTM::SpikeBy( 10, $core->get_type() );

            my $strength = $core->get_strength;

            # main::message("Strength for asking: $strength", 1);
            return unless SUtil::toss( $strength / 100 );
        }
    }
}

CodeletFamily FindIfRelated_deleteme( $a !, $b ! ) does {
INITIAL: {
        multimethod 'FindTransform';
    }
RUN: {
        return unless SWorkspace::__CheckLiveness( $a, $b );
        ( $a, $b ) = SWorkspace::__SortLtoRByLeftEdge( $a, $b );
        if ( $a->overlaps($b) ) {
            my ( $ul_a, $ul_b ) = ( $a->get_underlying_reln(), $b->get_underlying_reln() );
            return unless ( $ul_a and $ul_b );
            return unless $ul_a->get_rule() eq $ul_b->get_rule();
            return unless ($a->[-1] ~~ @$b); #i.e., actual subgroups overlap.
            CODELET ««Urgencies , FindIfRelated::MergeGroups»», MergeGroups, { a => $a, b => $b };
            return;
        }

        my $reln;
        if ( $reln = $a->get_relation($b) ) {

            # No need to create another.
            # But you may care to think about it some more
            spike_reln_type($reln);
            ContinueWith( SThought->create($reln) );
        }

        my $relntype = FindTransform($a, $b) // return;
        $reln = SRelation->new({first => $a,
                                second => $b,
                                type => $relntype
                               });
        my $type_activation = spike_reln_type($reln);
        return unless ( SUtil::toss($type_activation) );

        if ( $b->get_right_edge() >= $SWorkspace::ElementCount ) {
            print STDERR "Hmmm... problem traced back here\n";
        }
        $reln->AddHistory("Found relation!");

        # So a relation has been found
        $reln->insert;
        ContinueWith( SThought->create($reln) );

    }
FINAL: {

        sub spike_reln_type {
            my ($reln) = @_;
            my $reln_type = $reln->get_type();
            SLTM::InsertUnlessPresent($reln_type);

            my ( $l1, $r1, $l2, $r2 )
                = map { $_->get_edges() } ( $reln->get_first(), $reln->get_second() );

            #print "$l1, $r1, $l2, $r2\n";
            my $gap_size = List::Util::max( $l1, $l2 ) - List::Util::min( $r1, $r2 );

            #print "Gapsize: $gap_size\n";
            return if $gap_size <= 0;    # Bacuase overlapping relation, anyway
            my $extra_boost = ( $reln->isa('SReln::Compound') ) ? 10 : 3;
            my $type_activation = SLTM::SpikeBy( $extra_boost + int( 10 / $gap_size ), $reln_type );
            # return $type_activation;
            return 1; # XXX 
        }

    }
}

CodeletFamily AttemptExtensionOfGroup( $object !, $direction ! ) does {
INITIAL: {
        multimethod 'SanityCheck';
    }
RUN: {
        SWorkspace::__CheckLiveness($object) or return;
        my $underlying_reln = $object->get_underlying_reln();
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup pre" );
        }
        my $extension = $object->FindExtension($direction, 0) or return;
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup post" );
        }

        #print STDERR "\nExtending object: ", $object->as_text();
        #print STDERR "\nExtension found:", $extension->as_text();
        #print STDERR "\nDirection:", $direction;
        #main::message("Found extension: $extension; " . $extension->get_structure_string());
        my $add_to_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
        ## add_to_end_p (in SCF): $add_to_end_p
        my $extend_success;
        TRY {
            $extend_success = $object->Extend( $extension, $add_to_end_p );
        }
        CATCH {
        CouldNotCreateExtendedGroup: {
                my $msg = "Extending object: " . $object->as_text() . "\n";
                $msg .= "Extension: " . $extension->as_text() . " in direction $add_to_end_p\n";
                print STDERR $msg;
                main::message($msg);
            }
        }

        return unless $extend_success;
        if ( SUtil::toss( $object->get_strength() / 100 ) ) {
            CODELET ««Urgencies, AttemptExtensionOfGroup::AreWeDone »», AreWeDone, { group => $object };
        }

        #main::message("Extended!");

    }
FINAL: {

    }
}

CodeletFamily TryToSquint( $actual !, $intended ! ) does {
INITIAL: {

    }
RUN: {
        # main::message("In TryToSquint");
        my @potential_squints = $actual->CheckSquintability($intended) or return;
        #main::message("potential_squints: @potential_squints");
        my $chosen_squint = SLTM::SpikeAndChoose(100, @potential_squints) or return;
        #main::message("chosen_squint: $chosen_squint");

        my ($cat, $name) = $chosen_squint->GetCatAndName;
        #main::message("CAT/NAME: $cat, $name");
        $actual->AnnotateWithMetonym( $cat, $name );
        $actual->SetMetonymActiveness(1);

    }
FINAL: {

    }
}

CodeletFamily ConvulseEnd( $object !, $direction ! ) does {
INITIAL: {

    }
RUN: {
        unless ( SWorkspace::__CheckLiveness($object) ) {
            return;    # main::message("SCF::ConvulseEnd: " . $object->as_text());
        }
        my $change_at_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
        my @object_parts = @$object;
        my $ejected_object;
        if ($change_at_end_p) {
            $ejected_object = pop(@object_parts);
        }
        else {
            $ejected_object = shift(@object_parts);
        }

        my $underlying_reln = $object->get_underlying_reln();
        multimethod 'SanityCheck';
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "Pre-extension" );
        }

        my $new_extension = $object->FindExtension( $direction, 1 ) or return;
        if ( my $unstarred = $new_extension->get_is_a_metonym() ) {
            main::message("new_extension was metonym! fixing...");
            $new_extension = $unstarred;
        }
        if ( $new_extension and $new_extension ne $ejected_object ) {
            if ($underlying_reln) {
                SanityCheck( $object, $underlying_reln, "post-extension" );
            }

            my $structure_string_before_ejection = $object->as_text();
            if ($change_at_end_p) {
                $ejected_object = pop(@$object);
            }
            else {
                $ejected_object = shift(@$object);
            }
            SWorkspace::__RemoveFromSupergroups_of( $ejected_object, $object );
            $object->recalculate_edges();

            #main::message( "New extension! Instead of "
            #      . $ejected_object->as_text()
            #      . " I can use "
            #      . $new_extension->as_text() );
            my $extended = eval { $object->Extend( $new_extension, $change_at_end_p ) };
            if ( my $e = $EVAL_ERROR ) {
                if ( UNIVERSAL::isa( $e, "SErr::CouldNotCreateExtendedGroup" ) ) {
                    print STDERR "(structure before ejection): $structure_string_before_ejection\n";
                    print STDERR "Extending group: ", $object->as_text(), "\n";
                    print STDERR "(But effectively): ", $object->GetEffectiveStructureString();
                    print STDERR "Ejected object: ", $ejected_object->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $ejected_object->GetEffectiveStructureString();
                    print STDERR "New object: ", $new_extension->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $new_extension->GetEffectiveStructureString();
                    confess "Unable to extend group!";
                }
                confess $e;
            }
            unless ($extended) {

                # main::message("Failed to extend, and no deaths!");
                if ($change_at_end_p) {
                    push( @$object, $ejected_object );
                }
                else {
                    unshift( @$object, $ejected_object );
                }
                $object->recalculate_edges();
            }
        }

    }
FINAL: {

    }
}

CodeletFamily CheckProgress() does {
INITIAL: {
        our $last_time_progresschecker_run = 0;
    }
RUN: {
        our $last_time_progresschecker_run;
        my $time_since_last_addn    = $Global::Steps_Finished - $Global::TimeOfNewStructure;
        my $time_since_new_elements = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
        my $time_since_codelet_run  = $Global::Steps_Finished - $last_time_progresschecker_run;

        # Don't run too frequently
        return if $time_since_codelet_run < 100;
        $last_time_progresschecker_run = $Global::Steps_Finished;

        my $desperation = CalculateDesperation( $time_since_last_addn, $time_since_new_elements );

        my $chooser_on_inv_strength = SChoose->create( { map => q{100 - $_->get_strength()} } );
        if ( $desperation > 50 ) {
            main::ask_for_more_terms();
        }
        elsif ( $desperation > 30 ) {

            # XXX(Board-it-up): [2007/02/14] should be biased by 100 - strength?
            # my $gp = SChoose->uniform([SWorkspace::GetGroups()]);
            my $gp = $chooser_on_inv_strength->( [ SWorkspace::GetGroups() ] );
            if ($gp) {

                # main::message("Deleting group $gp: " . $gp->get_structure_string());
                SWorkspace->remove_gp($gp);
            }
        }
        elsif ( $desperation > 10 ) {
            for ( values %SWorkspace::relations ) {
                my $age = $_->GetAge();
                if (    SUtil::toss( ( 100 - $_->get_strength() ) / 200 )
                    and SUtil::toss( $age / 400 ) )
                {
                    $_->uninsert();
                }
            }
        }

    }
FINAL: {
        my @Cutoffs = ( [ 1500, 0, 80 ], [ 800, 2500, 80 ], [ 500, 0, 40 ], [ 200, 0, 20 ], );

        sub CalculateDesperation {
            my ( $time_since_last_addn, $time_since_new_elements ) = @_;
            for (@Cutoffs) {
                my ( $a, $b, $c ) = @$_;
                return $c if ( $time_since_last_addn >= $a
                    and $time_since_new_elements >= $b );
            }
            return 0;
        }
    }
}

CodeletFamily WorthAskingForExtendingReln( $core !, $direction !, $already_matched !,
    $ask_if_what !, $err ! ) does {
RUN: {
        confess "AM I STILL USING WorthAskingForExtendingReln?";

        #main::message("WorthAskingForExtendingReln called with " . join(', ', @$ask_if_what), 1);
        my $type_activation = SCF::FindIfRelated::spike_reln_type($core);
        if ( $type_activation < 0.3 or SUtil::toss( 1 - $type_activation ) ) {
            $SGUI::Commentary->MessageRequiringNoResponse(
                "Not asking if next terms " . join( ' ', @$ask_if_what ) . "\n" );
            return;
        }

        my $element_count                  = $SWorkspace::ElementCount;
        my $matched_elements_count         = scalar(@$already_matched);
        my $index_of_first_matched_element = $element_count - $matched_elements_count;
        my $trust;
        if ( $index_of_first_matched_element > 0 ) {
            my $largest_preceding_group = SWorkspace->get_longest_non_adhoc_object_ending_at(
                $index_of_first_matched_element - 1 );
            my $matched_elements_fraction = $matched_elements_count / $element_count;
            my $preceding_group_fraction  = $largest_preceding_group->get_span() / $element_count;
            my $core_span_ratio           = $core->get_span() / $element_count;

#main::message("Core Span Ratio: $core_span_ratio, matched_elements_fraction: $matched_elements_fraction, ".
#      "preceding_group_fraction: $preceding_group_fraction", 1);

            unless (
                   $core_span_ratio >= 0.5
                or $matched_elements_fraction > 0.2
                or (    $matched_elements_fraction + $preceding_group_fraction > 0.4
                    and $matched_elements_fraction < $preceding_group_fraction )
                )
            {
                return;
            }
            my $trust = 0.7 - ( 1 - $type_activation ) * ( 1 - $core_span_ratio );

            # main::message("trust: $trust");
            return if $trust < $Global::AcceptableTrustLevel;
        }

        # So worth asking?
        $err->Ask('Extending relation. ') or return;
        CODELET 100, AttemptExtensionOfRelation,
            {
            core      => $core,
            direction => $direction
            };
    }
}

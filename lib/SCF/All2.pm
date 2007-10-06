CodeletFamily Reader() does {
RUN: {
        if ( SUtil::toss(0.05) ) {
            ReadSamenessAroundReadHead();
            return;
        }
        my $object;
        if ( SUtil::toss(0.5) ) {
            $object = SWorkspace->read_object();
        }
        else {
            $object = SWorkspace->read_relation();

            # $logger->info("* Read Relation \n");
        }
        if ($object) {

            # main::message("read an SAnchored!") if (ref $object) eq "SAnchored";
            my $strength = $object->get_strength();

            # $logger->info("\tstrength: $strength\n");
            SThought->create($object)->schedule();
        }

    }

FINAL: {

        sub ReadSamenessAroundReadHead {
            my $readheadpos = $SWorkspace::ReadHead;
            my $magnitude   = ( SWorkspace::GetElements() )[$readheadpos]->get_mag();
            my ( $left_margin_of_sameness_gp, $right_margin_of_sameness_gp )
                = ( $readheadpos, $readheadpos );
            while ( $left_margin_of_sameness_gp > 0 ) {
                if ( ( SWorkspace::GetElements() )[ $left_margin_of_sameness_gp - 1 ]->get_mag()
                    == $magnitude )
                {
                    $left_margin_of_sameness_gp--;
                }
                else {
                    last;
                }
            }
            while ( $right_margin_of_sameness_gp <= $SWorkspace::ElementCount - 2 ) {
                if ( ( SWorkspace::GetElements() )[ $right_margin_of_sameness_gp + 1 ]->get_mag()
                    == $magnitude )
                {
                    $right_margin_of_sameness_gp++;
                }
                else {
                    last;
                }
            }
            my $span = $right_margin_of_sameness_gp - $left_margin_of_sameness_gp + 1;
            return if $span < 2;
            my $is_covering = scalar(
                SWorkspace::__GetObjectsWithEndsBeyond(
                    $left_margin_of_sameness_gp, $right_margin_of_sameness_gp
                )
            );
            return if $is_covering;
            my @items = ( SWorkspace::GetElements() )
                [ $left_margin_of_sameness_gp .. $right_margin_of_sameness_gp ];
            for (@items) {
                return if $_->get_metonym_activeness();
            }

            my $new_group = SAnchored->create(@items);
            eval { SWorkspace->add_group($new_group) };
            if ( my $e = $EVAL_ERROR ) {
                return if UNIVERSAL::isa( $e, 'SErr::ConflictingGroups' );
                confess $e;
            }
        }
    }
}

CodeletFamily CheckIfInstance( $obj !, $cat ! ) does {
RUN: {
        if ( $obj->describe_as($cat) ) {
            if ( $Global::Feature{LTM} ) {
                SLTM::SpikeBy( 10, $cat );
                SLTM::InsertISALink( $obj, $cat )->Spike(5);
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

        my $lit_cat = $S::LITERAL->build( { structure => [@structure] } );
## $lit_cat, ident $lit_cat
        my $bindings = $object->describe_as($lit_cat)
            or confess "Hey, should NEVER have failed!";
    }
}
#####################################
#####################################
# Given a relation and a direction it tries to extend it in that direction
# How it works
# find next position where extension starts
#   if extension is beyond known elements. fizzle with an 85% probability
# find out what the next object should be
# if the object is actually present, then a relation  is added to one of the original
# objects as appropriate, and category labels are added to the new object
#
# if, on the other hand, the new object lies in the unknown range, another codelet is
# launched that  checks if the user should be asked and extends the terms if possible
CodeletFamily AttemptExtensionOfRelation( $core !, $direction ! ) does {
INITIAL: {
        multimethod 'find_reln';
        multimethod 'apply_reln';
        multimethod '__PlonkIntoPlace';
    }
RUN: {
        my $direction_of_core = $core->get_direction;
        return
            unless $direction_of_core->PotentiallyExtendible();    # i.e., is LEFT or RIGHT
        my $type = $core->isa('SObject') ? "object" : "reln";

        if ( $type eq "object" ) {
            confess "The functionality of extending objects now done by AttemptExtensionOfGroup.";
        }

        ## $direction, $direction_of_core, $type

        my ( $reln, $obj1, $obj2, $next_pos );
        if ( $direction eq $direction_of_core ) {
            ( $reln, $obj1, $obj2 ) = ( $core, $core->get_ends );
        }
        else {
            ( $reln, $obj2, $obj1 ) = ( $core->FlippedVersion(), $core->get_ends );
        }

        if ( SWorkspace->are_there_holes_here( $obj1, $obj2 ) ) {

            # main::message("A relation had holes! Launching a AttemptExtensionOfLongRelation");
            CODELET 100, AttemptExtensionOfLongRelation, {
                effective_relation     => $reln,        # Already flipped if needed.
                obj1                   => $obj1,
                obj2                   => $obj2,
                direction_to_extend_in => $direction,
                core                   => $core,        # The real relation we are extending

            };
            return;
        }

        #main::message("AttemptExtensionOfRelation called (and no holes seen):" .
        #                  $obj1->as_text(). ', '. $obj2->as_text() . ' ==> '.
        #                  $core->as_text());

        $next_pos = $obj2->get_next_pos_in_dir($direction);
        return unless defined($next_pos);
        my $core_span = $core->get_span;
        DoTheExtension( $next_pos, $direction, $reln, $obj2, $core );
    }
FINAL: {

        sub DoTheExtension {
            my ($next_pos,     # Position where we expect to find next object.
                $direction,    # The direction we are extending in.
                $reln,         # The *effective* relation we are extending. If extending left from a
                               # rightward reln, this is a flip.
                $obj2,         # if direction to extend in is the same as direction of core,
                               # This is $core->second(), else its $core->first()
                $core,         # The actual relation being extended.
            ) = @_;
            my $what_next;
            my $direction_of_core = $core->get_direction();
            if ( $next_pos >= $SWorkspace::ElementCount ) {
                return unless SUtil::toss(0.15);
            }

            eval { $what_next = apply_reln( $reln, $obj2->GetEffectiveObject() ) }
                or return;
            if ($EVAL_ERROR) {
                ### eval error in apply reln!
                ### $reln
                ### $obj2
                exit;
            }

            # main::message("While extending, what_next is " . $what_next->get_structure_string(), 1);
            return unless @$what_next;    # Zero elements, hopeless!
                                          # Check that this is what is present...
            my $is_this_what_is_present;
            eval {
                # main::message("Will check at location: $next_pos, ". join(", ", @$what_next), 1);
                $is_this_what_is_present = SWorkspace->check_at_location(
                    {   start     => $next_pos,
                        direction => $direction,
                        what      => $what_next,
                    }
                );
                # main::message("is_this_what_is_present is $is_this_what_is_present", 1);
            };

            if ($EVAL_ERROR) {
                my $err = $EVAL_ERROR;

                # main::message("Good! Error caught");
                if ( UNIVERSAL::isa( $err, "SErr::AskUser" ) ) {
                    my $already_matched = $err->already_matched();
                    my $ask_if_what     = $err->next_elements();

                    # return unless worth_asking( $already_matched, $ask_if_what, $core_span );

                    CODELET 100, WorthAskingForExtendingReln, {
                        core            => $core,
                        direction       => $direction,
                        already_matched => $already_matched,
                        ask_if_what     => $ask_if_what,
                        err             => $err,               # so that we can call $err->Ask()
                    };
                    return;
                }
                else {
                    $err->rethrow;
                }
            }
            if ($is_this_what_is_present) {

                #main::message("And that was what was present", 1);
                my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $what_next );
                return unless $plonk_result->PlonkWasSuccessful();
                my $wso = $plonk_result->get_resultant_object();

                if ( $reln->isa('SReln::Compound') ) {
                    my $type = $reln->get_base_category;
                    ## Describe as: $type
                    $wso->describe_as($type) or return;
                }

                ## $wso, $wso->get_structure
                ## $direction, $direction_of_core
                ## $obj2->get_structure

                my $reln_to_add;
                if ( $direction eq $direction_of_core ) {
                    $reln_to_add = find_reln( $obj2, $wso );
                }
                else {
                    $reln_to_add = find_reln( $wso, $obj2 );
                }

                if ($reln_to_add) {
                    $reln_to_add->insert;
                }
                else {

                    # ToDo: [2006/09/27] For ad_hoc, the constucted object has type ad_hoc, but it's
                    # constituents are not correctly typed
                    #   main::message("No relation found to insert!");
                }
            }
            else {

                # maybe attempt extension
                if ( SUtil::toss(0.5) ) {
                    return;
                }
                else {
                    CODELET 100, AreTheseGroupable,
                        {
                        items => [ $core->get_ends() ],
                        reln  => $core
                        };
                }
            }

        }

        sub worth_asking {
            my ( $matched, $unmatched, $extension_from_span ) = @_;
            return 1 if ( @$matched > 0 );
            my $time_since_extension = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
            my $number_of_user_verified_elements
                = $SWorkspace::ElementCount - $Global::InitialTermCount;
            return if $time_since_extension < 10 * $number_of_user_verified_elements;

        # main::message("Verified: $number_of_user_verified_elements; Time: $time_since_extension");
            ### $matched
            ### $unmatched
            my $penetration
                = ( scalar(@$matched) + $extension_from_span ) / $SWorkspace::ElementCount;

            # print STDERR "Penetration: $penetration\n";
            return unless $penetration;

            my $on_a_limb = scalar(@$unmatched) / ( scalar(@$matched) + $extension_from_span );

            # print STDERR "On a limb: $on_a_limb\n";
            return 1 if ( $penetration > 0.5 and $on_a_limb < 0.85 );
            return;
        }

    }
}

CodeletFamily AttemptExtensionOfLongRelation( $core !, $effective_relation !,
    $obj1 !, $obj2 !, $direction_to_extend_in ! ) does {
RUN: {

        #main::message("AttemptExtensionOfLongRelation run!");
        my $direction_of_core = $effective_relation->get_direction();
        ### require: $direction_of_core eq $direction_to_extend_in
        # but not necessarily $core->get_direction() eq $direction_to_extend_in

        #return unless $direction_of_core->PotentiallyExtendible();
        my $distance = SWorkspace::__FindDistance( $obj1, $obj2 );
        unless ($distance) {
            print "distance undef/0 in AttemptExtensionOfLongRelation\n";
            print $obj1->as_text(), "\n", $obj2->as_text(), "\n";
            confess "distance undef/0 in AttemptExtensionOfLongRelation\n";
        }
        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $obj2,    # Assumption: We are called by AttemptExtensionOfRelation,
                                         # and direction_of_core == direction_to_extend_in
                direction => $direction_to_extend_in,
                distance  => $distance,
            }
        );
        return unless defined $next_pos;
        return if $next_pos > $SWorkspace::ElementCount;
        SCF::AttemptExtensionOfRelation::DoTheExtension( $next_pos, $direction_to_extend_in,
            $effective_relation, $obj2, $core, );

        #main::message("While extending " . $core->as_text() . " with end object ".
        #                  $obj2->as_text() . ' in direction ' . $direction_to_extend_in->as_text().
        #                      " the distance was " . $distance->as_text() . ", and next position $next_pos."
        #                  );
    }
}

CodeletFamily flipReln( $reln ! ) does {
INITIAL: {
        multimethod 'find_reln';
    }
RUN: {
        my $new_reln = $reln->FlippedVersion() or return;
        $reln->uninsert;
        $new_reln->insert;
    }
FINAL: {

    }
}

CodeletFamily FindIfRelated( $a !, $b ! ) does {
INITIAL: {
        multimethod 'find_reln';
    }
RUN: {
        return if ( $a->overlaps($b) );
        return unless SWorkspace::__CheckLiveness($a, $b);
        unless ( $Global::Feature{AllowLeftwardRelations} ) {
            ( $a, $b ) = SWorkspace::__SortLtoRByLeftEdge( $a, $b );
        }

        my $reln;
        if ( $reln = $a->get_relation($b) ) {

            # No need to create another.
            # But you may care to think about it some more
            spike_reln_type($reln);
            ContinueWith( SThought->create($reln) );
        }

## Running FindIfRelated: $a, $b
        $reln = find_reln( $a, $b ) or return;

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
            return 1 unless ( $Global::Feature{relnact} or $Global::Feature{rules} );
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
            return 1 unless $Global::Feature{relnact};

            return $type_activation;
        }

    }
}

CodeletFamily FindIfRelatedRelns( $a !, $b ! ) does {
INITIAL: {
        multimethod 'are_relns_compatible';
    }
RUN: {
        my ( $af, $as, $bf, $bs ) = ( $a->get_ends(), $b->get_ends() );

        # check if there is any intersection at all
        my %edge_hash;
        my $hit;
        for ( $af, $as, $bf, $bs ) {
            my $count = ++$edge_hash{$_};
            $hit = $_ if $count > 1;
        }
        return unless $hit;

        # It could be that af=bf or as=bs, which'd mean that we may want to flip one of them.
        # or it could be that bs=af, in which case their roles will need to be switched

        if ( $af eq $bf or $as eq $bs ) {
            # If they are in the same direction, they are unrelated.
            my $da = $a->get_direction();
            my $db = $b->get_direction();
            return if(!$da->IsLeftOrRight() or !$db->IsLeftOrRight());
            return if $da eq $db;

            # choose one of these to flip
            # XXX weaker!!
            my $maybe_check_flippability = SChoose->choose( [ $a, $b ] );
            my $tht = CODELET 100, ShouldIFlip, { reln => $maybe_check_flippability };
            return;
        }

        if ( $af eq $bs ) {    # need to flip roles!
            ( $a, $b, $af, $bf, $as, $bs ) = ( $b, $a, $bf, $af, $bs, $as );
        }

        # Must be teh case that as is bf. Now we need to see if they are compatible
        my $compatibility = are_relns_compatible( $a, $b );
        if ($compatibility) {
            CODELET 100, AreTheseGroupable,
                {   items => [ $af, $as, $bs ],
                    reln  => $a,
                };
            return;
        }

    }
FINAL: {

    }
}

CodeletFamily AttemptExtensionOfGroup( $object !, $direction ! ) does {
INITIAL: {
        multimethod 'SanityCheck';
    }
RUN: {

        #main::message("Starting SCF::AttemptExtensionOfGroup");
        my $underlying_reln = $object->get_underlying_reln();
        unless ( SWorkspace::__CheckLiveness($object) ) {
            return;

            #main::message("Aha! group is NOT in w/s" . $object->as_text());
        }
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup pre" );
        }
        my $extension = $object->FindExtension( $direction, 0 ) or return;
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup post" );
        }

        #print STDERR "\nExtending object: ", $object->as_text();
        #print STDERR "\nExtension found:", $extension->as_text();
        #print STDERR "\nDirection:", $direction;
        #main::message("Found extension: $extension; " . $extension->get_structure_string());
        my $add_to_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
        ## add_to_end_p (in SCF): $add_to_end_p
        my $extend_success = eval { $object->Extend( $extension, $add_to_end_p ); };
        if ( my $e = $EVAL_ERROR ) {
            if ( UNIVERSAL::isa( $e, 'SErr::CouldNotCreateExtendedGroup' ) ) {
                my $msg = "Extending object: " . $object->as_text() . "\n";
                $msg .= "Extension: " . $extension->as_text() . " in direction $add_to_end_p\n";
                print STDERR $msg;
                main::message($msg);
            }
            confess($e);
        }
        return unless $extend_success;
        ContinueWith( SThought::AreWeDone->new( { group => $object } ) )
            if SUtil::toss( $object->get_strength() / 100 );

        #main::message("Extended!");

    }
FINAL: {

    }
}

CodeletFamily TryToSquint( $actual !, $intended ! ) does {
INITIAL: {

    }
RUN: {

#main::message("Wonder if I can see " . $actual->as_text() . " as a " . $intended->get_structure_string());
# XXX(Board-it-up): [2006/12/29] Clearly suboptimal, and also brute-forcey...
        my @potential_squints = $actual->CheckSquintability($intended) or return;

        # XXX(Board-it-up): [2006/12/29] choose wisely!
        my ( $cat, $name ) = @{ $potential_squints[0] };

        #main::message("Squinting: $cat/$name");
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

CodeletFamily TryRule( $rule !, $reln ! ) does {
INITIAL: {

    }
RUN: {

        #main::message("Will try rule $rule");
        my $direction = $reln->get_direction();

        # XXX(Board-it-up): [2007/01/01] for now...
        return unless $direction eq $DIR::RIGHT;
        return unless SUtil::toss( $rule->suitability() );

        my $application = $rule->AttemptApplication(
            {   start     => $reln->get_first(),
                terms     => 4,
                direction => $DIR::RIGHT,
            }
        );
        if ($application) {

            #main::message("Application of rule succeded! " . $rule->as_text());
            $application->ExtendLeftMaximally();
            my $new_group = SAnchored->create( @{ $application->get_items() } );
            SWorkspace->add_group($new_group) or return;
            THOUGHT AreWeDone, { group => $new_group };
        }
        else {

            #main::message("Application of rule failed: " . $rule->as_text());
            $rule->Reject();
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
        $err->Ask('extending relation') or return;
        CODELET 100, AttemptExtensionOfRelation,
            {
            core      => $core,
            direction => $direction
            };
    }
}

#####################################
#####################################
use Compile::SCF;
[package] SCF::Reader
<run>
    my $object;
    if ( SUtil::toss(0.5) ) {
        $object = SWorkspace->read_object();
        if ( LOGGING_INFO() and $object ) {
            my ( $l, $r, $s )
                = ( $object->get_left_edge, $object->get_right_edge, $object->get_structure, );
            my $strength = $object->get_strength();
            my $msg = "* Read Object: \t[$l,$r] $s\n";
            $logger->info($msg);
        }
    }
    else {
        $object = SWorkspace->read_relation();
        $logger->info("* Read Relation \n");
    }
    if ($object) {
        # main::message("read an SAnchored!") if (ref $object) eq "SAnchored";
        my $strength = $object->get_strength();
        $logger->info("\tstrength: $strength\n");
        SThought->create($object)->schedule();
    }
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::CheckIfInstance
[param] obj!
[param] cat!
<run>
    $obj->describe_as($cat) and SLTM::SpikeBy( 10, $cat );
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::SetLiteralCat
[param] object!
<run>
    my @structure;
    if ($object->get_metonym_activeness) {
        @structure = $object->get_metonym()->get_starred->get_structure();
    } else {
        @structure = 
            map { $_->get_structure }
                map { $_->GetEffectiveObject } 
                    @{$object->get_parts_ref};
        ## @structure
    }
    
    my $lit_cat = $S::LITERAL->build({ structure => [@structure] });
    ## $lit_cat, ident $lit_cat
    my $bindings = $object->describe_as( $lit_cat ) or confess "Hey, should NEVER have failed!";
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::AttemptExtensionOfRelation
[multi] find_reln
[multi] apply_reln
[multi] plonk_into_place

[param] core!
[param] direction!

<run>
    my $direction_of_core = $core->get_direction;
    return unless $direction_of_core->PotentiallyExtendible(); # i.e., is LEFT or RIGHT
    my $type = $core->isa('SObject') ? "object" : "reln";

    if ($type eq "object") {
        confess "The functionality of extending objects now done by AttemptExtensionOfGroup.";
    }

    ## $direction, $direction_of_core, $type

    my ( $reln, $obj1, $obj2, $next_pos, $what_next );
    if ($direction eq $direction_of_core) {
        ($reln, $obj1, $obj2 ) = ($core, $core->get_ends );
    } else {
        ($reln, $obj2, $obj1 ) = ($core->FlippedVersion(), $core->get_ends );
    }

    $next_pos = $obj2->get_next_pos_in_dir( $direction );
    return unless defined($next_pos);

    eval { $what_next = apply_reln( $reln, $obj2->GetEffectiveObject() )} or return;
    if ($EVAL_ERROR) {
        ### eval error in apply reln!
        ### $reln
        ### $obj2
        exit;
    }

    my $core_span = $core->get_span;
    
    # Check that this is what is present...
    my $is_this_what_is_present;
    eval {$is_this_what_is_present= 
              SWorkspace->check_at_location({ start => $next_pos,
                                              direction => $direction,
                                              what => $what_next,
                                          }
                                                );
      };

    if ($EVAL_ERROR) {
        my $err = $EVAL_ERROR;
        # main::message("Good! Error caught");
        if (UNIVERSAL::isa($err, "SErr::AskUser")) {
            my $already_matched = $err->already_matched();
            my $ask_if_what = $err->next_elements();
            #main::message("already_matched @$already_matched; span = $core_span");
            if (worth_asking($already_matched, $ask_if_what, $core_span)) {
                # main::message("We may ask the user if the next elements are: @$ask_if_what");
                my $ans = $err->Ask('(Extending relation)'); 
                if ($ans) {
                    $is_this_what_is_present = 1;
                } else {
                    $core->set_right_extendibility( EXTENDIBILE::NO());
                }
            } else {
                #main::message("decided not to ask if next are @$ask_if_what");
            }
            return;
        } else {
            $err->rethrow;
        }
    }
    if ($is_this_what_is_present) {
        my $wso = plonk_into_place($next_pos, 
                                   $direction,
                                   $what_next
                                       );

        return unless $wso;

        if ($reln->isa('SReln::Compound')) {
            my $type = $reln->get_base_category;
            ## Describe as: $type
            $wso->describe_as( $type ) or return;
        }

        ## $wso, $wso->get_structure
        ## $direction, $direction_of_core
        ## $obj2->get_structure


        my $reln_to_add;
        if ($direction eq $direction_of_core) {
            $reln_to_add = find_reln($obj2, $wso);
        } else {
            $reln_to_add = find_reln($wso, $obj2);
        }

        if ($reln_to_add) {
            $reln_to_add->insert;
        } else {
            # ToDo: [2006/09/27] For ad_hoc, the constucted object has type ad_hoc, but it's
            # constituents are not correctly typed
            #   main::message("No relation found to insert!");
        }
    } else {
        # maybe attempt extension
        if ($direction eq DIR::RIGHT()) {
            $core->set_right_extendibility( EXTENDIBILE::NO() );
        } elsif ($direction eq DIR::LEFT()) {
            $core->set_left_extendibility( EXTENDIBILE::NO() );
        }
        if (SUtil::toss(0.5)) {
            return;
        } else {
            my $tht = new SThought::AreTheseGroupable
                ( { items => [$core->get_ends()],
                    reln  => $core
                        });
            ContinueWith( $tht );
        }
    }
</run>

sub worth_asking{
    my ( $matched, $unmatched, $extension_from_span ) = @_;
    my $time_since_extension = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
    my $number_of_user_verified_elements = $SWorkspace::elements_count - $Global::InitialTermCount;
    return if $time_since_extension < 10 * $number_of_user_verified_elements;
    # main::message("Verified: $number_of_user_verified_elements; Time: $time_since_extension");
    ### $matched
    ### $unmatched
    my $penetration = (scalar(@$matched) + $extension_from_span) / $SWorkspace::elements_count;
    # print STDERR "Penetration: $penetration\n";
    return unless $penetration;

    my $on_a_limb = scalar(@$unmatched)/(scalar(@$matched) + $extension_from_span);
    # print STDERR "On a limb: $on_a_limb\n";
    return 1 if ($penetration > 0.2 and $on_a_limb < 0.85);
    return;
}

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::flipReln;
[multi] find_reln
[param] reln!

<run>
    my $new_reln = $reln->FlippedVersion() or return;
    $reln->uninsert;
    $new_reln->insert;
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::FindIfRelated
[multi] find_reln
[param] a!
[param] b!

<run>
    return if ($a->overlaps($b));

    unless ($Global::Feature{AllowLeftwardRelations}) {
        ($a, $b) = SWorkspace::SortLeftToRight($a, $b);
    }

    my $reln;
    if ($reln = $a->get_relation($b)) {
        # No need to create another.
        # But you may care to think about it some more
        spike_reln_type($reln);
        ContinueWith(SThought->create($reln));
    }

    ## Running FindIfRelated: $a, $b
    $reln = find_reln( $a, $b ) or return;

    my $type_activation = spike_reln_type($reln);
    return unless (SUtil::toss($type_activation));

if ($b->get_right_edge() >= $SWorkspace::elements_count) {
    print STDERR "Hmmm... problem traced back here\n";
}
    $reln->AddHistory("Found relation!");

    # So a relation has been found
    $reln->insert;
    ContinueWith(SThought->create($reln));
</run>

sub spike_reln_type{
    my ( $reln ) = @_;
    return 1 unless ($Global::Feature{relnact} or $Global::Feature{rules});
    my $reln_type = $reln->get_type();
    SLTM::InsertUnlessPresent($reln_type);

    my ( $l1, $r1, $l2, $r2 )
            = map { $_->get_edges() } ( $reln->get_first(), $reln->get_second() );
    #print "$l1, $r1, $l2, $r2\n";
    my $gap_size =  List::Util::max( $l1, $l2 ) - List::Util::min( $r1, $r2 );
    #print "Gapsize: $gap_size\n";
    return if $gap_size <=0; # Bacuase overlapping relation, anyway
    my $extra_boost = ($reln->isa('SReln::Compound')) ? 10 : 3;
    my $type_activation = SLTM::SpikeBy($extra_boost + int(10/$gap_size), $reln_type);
    return 1 unless $Global::Feature{relnact};

    return $type_activation;
}


no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::FindIfMetonyable
[param] object!
[param] category!
<run>
    my @meto_types = $category->get_meto_types;
    # XXX(Board-it-up): [2006/10/14] Choose biased!
    my $meto_type = $meto_types[0];
    $object->AnnotateWithMetonym($category, $meto_type);
    $object->SetMetonymActiveness(1);
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::FindIfGroupable
[param] category!
[param] items!

<run>
    my $items_ref = $items;
    my $object;
    # We'll check if all items are anchored
    # Look at the items: all or none should be SAnchored
    my @anchored_p = map { UNIVERSAL::isa($_, "SAnchored") ?1:0} @$items_ref;
    my $anchored_count = sum(@anchored_p);

    ## Got here in FindIfGroupable

    if ($anchored_count == scalar( @anchored_p ) ) {
        my @unstarred_items = map { my $unstarred = $_->get_is_a_metonym();
                                    if ($unstarred) {
                                        main::message("unstarred seen!");
                                    } else {
                                        main::message("unstarred not seen!");
                                    }
                                $unstarred ? $unstarred : $_ } @$items_ref;
        eval { $object = SAnchored->create( @unstarred_items ) };
        if (my $e = $EVAL_ERROR) {
            if (UNIVERSAL::isa($e, "SErr::HolesHere")) {
                return;
            } else {
                die $e; 
            }
        } else { # So: object created.
            if (SWorkspace->get_all_groups_with_exact_span($object->get_edges())) {
                return;
            }
            
        }
    } elsif (!$anchored_count) { # none anchored
        $object = SObject->new({ items   => $items_ref,
                                    group_p => 1,
                                });
    } else {
        # some anchored, some unanchored
        SErr->throw( "There are some unanchored and some anchored objects that were passed to me. There is a serious flaw somewhere" );
    }

    ### Object created: $object

    my $bindings = $category->is_instance( $object ); 

    ### Bindings: $bindings

    return unless $bindings;
    if ($object->isa("SAnchored")) {
        SWorkspace->add_group($object) or return;
    }

    SCodelet->new("FindIfMetonyable", 50)->schedule();
    SThought->create( $object )->schedule();

</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::FindIfRelatedRelns
[multi] are_relns_compatible
[param] a!
[param] b!

<run>
    my ($af, $as, $bf, $bs) = ($a->get_ends(), $b->get_ends());
    
    # check if there is any intersection at all
    my %edge_hash;
    my $hit;
    for ($af, $as, $bf, $bs) { 
        my $count = ++$edge_hash{$_};
        $hit = $_ if $count > 1;
    }
    return unless $hit;

    # It could be that af=bf or as=bs, which'd mean that we may want to flip one of them.
    # or it could be that bs=af, in which case their roles will need to be switched

    if ($af eq $bf or $as eq $bs) {
        # choose one of these to flip
        # XXX weaker!!
        my $maybe_check_flippability = SChoose->choose([$a, $b]);
        my $tht = SThought::ShouldIFlip->new({reln => $maybe_check_flippability});
        SErr::NeedMoreData->new(payload => $tht)->throw()
    }

    if ($af eq $bs) { # need to flip roles!
        ($a, $b, $af, $bf, $as, $bs) = ($b, $a, $bf, $af, $bs, $as);
    }

    # Must be teh case that as is bf. Now we need to see if they are compatible
    my $compatibility = are_relns_compatible($a, $b);
    if ($compatibility) {
        my $tht = SThought::AreTheseGroupable->new({items => [$af, $as, $bs],
                                                    reln  => $a,
                                                });
        SErr::NeedMoreData->new(payload=> $tht)->throw();
    }
</run>
no Compile::SCF;
#############################################
use Compile::SCF;
[package] SCF::AttemptExtensionOfGroup
[param] object!
[param] direction!
[multi] SanityCheck
<run>
    #main::message("Starting SCF::AttemptExtensionOfGroup");
    my $underlying_reln = $object->get_underlying_reln();
unless (exists $SWorkspace::groups{$object}) {
    return;
    #main::message("Aha! group is NOT in w/s" . $object->as_text());
}
if ($underlying_reln) {
    SanityCheck($object, $underlying_reln, "In AttemptExtensionOfGroup pre");
}
    my $extension = $object->FindExtension($direction, 0) or return;
if ($underlying_reln) {
    SanityCheck($object, $underlying_reln, "In AttemptExtensionOfGroup post");
}
    #print STDERR "\nExtending object: ", $object->as_text();
    #print STDERR "\nExtension found:", $extension->as_text();
    #print STDERR "\nDirection:", $direction;
    #main::message("Found extension: $extension; " . $extension->get_structure_string());
    my $add_to_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
    ## add_to_end_p (in SCF): $add_to_end_p
    eval { $object->Extend( $extension, $add_to_end_p ); };
if (my $e = $EVAL_ERROR) {
    if (UNIVERSAL::isa($e, 'SErr::CouldNotCreateExtendedGroup')) {
        my $msg = "Extending object: " . $object->as_text() . "\n";
        $msg .= "Extension: " . $extension->as_text() . " in direction $add_to_end_p\n";
        print STDERR $msg;
        main::message($msg);
    }
    confess($e);
}
    ContinueWith( SThought::AreWeDone->new({group => $object}) ) 
       if SUtil::toss($object->get_strength() / 100); 
    #main::message("Extended!");
</run>
no Compile::SCF;
##############################################
use Compile::SCF;
[package] SCF::TryToSquint
[param] actual!
[param] intended!

<run>
#main::message("Wonder if I can see " . $actual->as_text() . " as a " . $intended->get_structure_string());
# XXX(Board-it-up): [2006/12/29] Clearly suboptimal, and also brute-forcey...
my @potential_squints = $actual->CheckSquintability($intended) or return;
# XXX(Board-it-up): [2006/12/29] choose wisely!
my ($cat, $name) = @{$potential_squints[0]};
#main::message("Squinting: $cat/$name");
$actual->AnnotateWithMetonym($cat, $name);
$actual->SetMetonymActiveness(1);
</run>

no Compile::SCF;
####################
use Compile::SCF;
[package] SCF::ConvulseEnd
[param] object!
[param] direction!

<run>
    unless (exists $SWorkspace::groups{$object}) {
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
            SanityCheck($object, $underlying_reln, "Pre-extension");
        }

    my $new_extension = $object->FindExtension($direction, 1) or return;
    if (my $unstarred = $new_extension->get_is_a_metonym()) {
        main::message("new_extension was metonym! fixing...");
        $new_extension = $unstarred;
    }
    if ( $new_extension and $new_extension ne $ejected_object ) {
        if ($underlying_reln) {
            SanityCheck($object, $underlying_reln, "post-extension");
        }

        my $structure_string_before_ejection = 
            $object->as_text();
        if ($change_at_end_p) {
            $ejected_object = pop(@$object);
        }
        else {
            $ejected_object = shift(@$object);
        }
        $object->recalculate_edges();
        
        #main::message( "New extension! Instead of "
        #      . $ejected_object->as_text()
        #      . " I can use "
        #      . $new_extension->as_text() );
        my $extended = eval { $object->Extend( $new_extension, $change_at_end_p ) };
        if (my $e = $EVAL_ERROR) {
            if (UNIVERSAL::isa($e, "SErr::CouldNotCreateExtendedGroup")) {
                print STDERR "(structure before ejection): $structure_string_before_ejection\n";
                print STDERR "Extending group: ", $object->as_text(), "\n";
                print STDERR "(But effectively): ", $object->GetEffectiveStructureString();
                print STDERR "Ejected object: ", $ejected_object->get_structure_string(), "\n";
                print STDERR "(But effectively): ", $ejected_object->GetEffectiveStructureString();
                print STDERR "New object: ", $new_extension->get_structure_string(), "\n";
                print STDERR "(But effectively): ", $new_extension->GetEffectiveStructureString();
                confess "Unable to extend group!";
            }
            confess $e;
        }
        unless ($extended) {
            # main::message("Failed to extend, and no deaths!");
            if ($change_at_end_p) {
                push(@$object, $ejected_object);
            }
            else {
                unshift(@$object, $ejected_object);
            }
            $object->recalculate_edges();            
        }
    }
</run>
no Compile::SCF;
#################################
use Compile::SCF;
[package] SCF::TryRule
[param] rule!
[param] reln!

<run>
   #main::message("Will try rule $rule");
   my $direction = $reln->get_direction();

   # XXX(Board-it-up): [2007/01/01] for now...
   return unless $direction eq $DIR::RIGHT;
   return unless SUtil::toss($rule->suitability());

   my $application = $rule->AttemptApplication({start => $reln->get_first(),
                                                terms => 4,
                                                direction => $DIR::RIGHT,
                                                   });
   if ($application) {
       #main::message("Application of rule succeded! " . $rule->as_text());
       $application->ExtendLeftMaximally();
       my $new_group = SAnchored->create(@{$application->get_items()});
       $new_group->set_right_extendibility($EXTENDIBILE::PERHAPS);
       SWorkspace->add_group($new_group) or return;
       ContinueWith( SThought::AreWeDone->new({group => $new_group}) );
   } else {
       #main::message("Application of rule failed: " . $rule->as_text());
       $rule->Reject();
   }
</run>
no Compile::SCF;
#################################
use Compile::SCF;
[package] SCF::CheckProgress

our $last_time_codelet_run = 0;
<run>
    our $last_time_codelet_run;
    my $time_since_last_addn = $Global::Steps_Finished - $Global::TimeOfNewStructure;
    my $time_since_new_elements = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
    my $time_since_codelet_run = $Global::Steps_Finished - $last_time_codelet_run;

return if $time_since_codelet_run < 100;
$last_time_codelet_run = $Global::Steps_Finished;

if ($time_since_new_elements > 2500) {
    main::ask_for_more_terms();
} elsif ($time_since_last_addn > 150) {
    # XXX(Board-it-up): [2007/02/14] should be biased by 100 - strength?
    my $gp = SChoose->uniform([values %SWorkspace::groups]);
    if ($gp) {
        # main::message("Deleting group $gp: " . $gp->get_structure_string());
        SWorkspace->remove_gp($gp);
    }
}
</run>
1;

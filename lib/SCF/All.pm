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
        my $strength = $object->get_strength();
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
    $obj->describe_as($cat);
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
                map { $_->get_effective_object } 
                    @{$object->get_parts_ref};
        ## @structure
    }
    
    my $lit_cat = $S::LITERAL->build({ structure => [@structure] });
    ## $lit_cat, ident $lit_cat
    my $bindings = $object->describe_as( $lit_cat );
    ## $bindings
    unless ($bindings) {
        confess "Hey, should NEVER have failed!";
    }
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::AttemptExtension
[multi] find_reln
[multi] apply_reln
[multi] plonk_into_place

[param] core!
[param] direction!

<run>
    my $direction_of_core = $core->get_direction;
    my $type = $core->isa('SObject') ? "object" : "reln";

    ## $direction, $direction_of_core, $type

    my ( $reln, $obj1, $obj2, $next_pos, $what_next );
    if ($direction == $direction_of_core) {
        if ($type eq "reln") {
            ($reln, $obj1, $obj2 ) = ($core, $core->get_ends );
        } else {
            $reln = $core->get_underlying_reln() or return;
            $obj2 = $core->[-1];
        }
    } else {
        if ($type eq "reln") {
            ($reln, $obj2, $obj1 ) = ($core->get_inverse, $core->get_ends );
        } else {
            $reln = $core->get_underlying_reln()->get_inverse() or return;
            $obj2 = $core->[0];
        }
    }

    $next_pos = $obj2->get_next_pos_in_dir( $direction );
    return unless defined($next_pos);

    eval { $what_next = apply_reln( $reln, $obj2 )} or return;
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
                my $ans = main::ask_user_extension($ask_if_what);
                if ($ans) {
                    $is_this_what_is_present = 1;
                    SWorkspace->insert_elements( @$ask_if_what );
                    $Global::Break_Loop = 1;
                } else {
                    my $seq = join(", ", @$ask_if_what);
                    ## setting for rejection: $seq
                    $Global::ExtensionRejectedByUser{ $seq } = 1;
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
        if ($direction == $direction_of_core) {
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


        if ($type eq "object") {
            my $core_object_ref = $core->get_parts_ref();
            if ($direction == $direction_of_core) {
                push @$core_object_ref, $wso;
            } else {
                unshift @$core_object_ref, $wso;
            }
            $core->recalculate_edges();
            $core->recalculate_categories();
            $core->recalculate_relations();
            $core->UpdateStrength();
            ## HERE
            ContinueWith( SThought::AreWeDone->new({group => $core}) );
        }
        # main::message("Okay, extended");
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
            if ($type eq 'object') {
                # ???
            } else {
                my $tht = new SThought::AreTheseGroupable
                    ( { items => [$obj1, $obj2],
                        reln  => $core
                    });
                ContinueWith( $tht );
            }
        }
    }
</run>

sub worth_asking{
    my ( $matched, $unmatched, $extension_from_span ) = @_;
    ## $matched
    ## $unmatched
    my $penetration = (scalar(@$matched) + $extension_from_span) / $SWorkspace::elements_count;
    ## $penetration
    return unless $penetration;

    my $on_a_limb = scalar(@$unmatched)/(scalar(@$matched) + $extension_from_span);
    return 1 if ($penetration > 0.3 and $on_a_limb < 0.8);
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
    my ($f, $s) = $reln->get_ends();
#XXX: Should be based on same category!
    my $new_reln = find_reln($s, $f);
    return unless $new_reln; 
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
    if ($a->overlaps($b)) {
        return;
    }

    my $reln;
    if ($reln = $a->get_relation($b)) {
        # No need to create another.
        # But you may care to think about it some more
        ContinueWith(SThought->create($reln));
    }

    ## Running FindIfRelated: $a, $b
    $reln = find_reln( $a, $b );
    return unless $reln;

    # So a relation has been found
    $reln->insert;
    ContinueWith(SThought->create($reln));
</run>

no Compile::SCF;
#####################################
#####################################
use Compile::SCF;
[package] SCF::FindIfMetonyable
[param] object!
[param] category!
<run>
    my @meto_types = $category->get_meto_types;
    my $meto_type = $meto_types[0]; #XXX
    $object->annotate_with_metonym($category, $meto_type);
    $object->set_metonym_activeness(1);
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
        eval { $object = SAnchored->create( @$items_ref ) };
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
        SWorkspace->add_group($object);
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

1;

##########################################
##########################################
use Compile::SThought;
[package] SThought::AreRelated
[param] a!
[param] b!
<fringe>

</fringe>

<actions>
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
</actions>

##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::AreTheseGroupable
 [param] items!
 [param] reln!


 <fringe>
     foreach (@$items) {
         FRINGE 20, $_;
     }
 </fringe>

 <actions>
    # Check if these are already grouped...
    # to do that, we need to find the left and right edges
    my ( @left_edges, @right_edges );
    for (@$items) {
        push @left_edges,  $_->get_left_edge;
        push @right_edges, $_->get_right_edge;
    }
    my $left_edge  = min(@left_edges);
    my $right_edge = max(@right_edges);
    my $is_covering =
      SWorkspace->is_there_a_covering_group( $left_edge, $right_edge );
    return if $is_covering;

    my $new_group;
    eval {
        # I do not see why I had the next line! Effective object are starred!
        #my @unstarred_items = map { $_->GetEffectiveObject() } @$items;
        my @unstarred_items = map { $_->GetUnstarred() } @$items;
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
        print "HERE IN SThought::AreTheseGroupable, error is $e of type ",
          ref($e), "\n";
        confess $e;
    }

# confess "@SWorkspace::OBJECTS New group created: $new_group, and added it to w/s";

 </actions>

##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::AreWeDone
 [param] group!

 <fringe>

 </fringe>

 <actions>
    my $gp          = $group;
    my $span        = $gp->get_span;
    my $total_count = $SWorkspace::elements_count;
    my $right_extendibility = $gp->get_right_extendibility();
    ### $span, $total_count
    #main::message( $right_extendibility);

    if ( $Global::AtLeastOneUserVerification
        and ( $span / $total_count ) > 0.8 )
    {

        # This very well may be it!
        if ( $gp->get_left_edge() != 0 ) {
            if ( $gp->get_left_extendibility() ne EXTENDIBILE::NO() ) {
                ACTION 80, AttemptExtensionOfGroup,
                  {
                    object    => $gp,
                    direction => DIR::LEFT()
                  };
            }
            else {
                if ( $total_count - $span == $gp->get_left_edge ) {
                    BelieveBlemish();
                }
            }
        }
        else {

            # so flush left
            if ( $span == $total_count ) {
                #Bingo!
                # XXX(Board-it-up): [2007/01/15] Some problem with get_right_extendibility, hence next line funny
                if ( 1 or $gp->get_right_extendibility() ne EXTENDIBILE::NO() ) {

                    #great.
                    main::update_display();
                    BelieveDone();
                }
                else {
                    main::update_display();
                    my $rejected =
                      join( ", ", keys %Global::ExtensionRejectedByUser );
                    my $msg = "I think I am stuck. ";
                    $msg .=
"You have already rejected {$rejected} as possible continuation(s)";
                    main::message($msg);
                }
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

 </actions>

sub BelieveDone{
    my ( $group ) = @_;
    if ($Global::TestingMode) {
        # Currently assume belief always right.
        SErr::FinishedTest->new(got_it => 1)
              ->throw();
    }
    main::message("I believe I got it");    
}

sub BelieveBlemish{
    if ($Global::TestingMode) {
        SErr::FinishedTestBlemished->new()->throw();
    }
    main::message("I believe this group has a blemish at the beginning");
}

##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::SAnchored
 [param] core!

multimethod get_fringe_for => ('SAnchored') => sub {
    my ($core) = @_;
    my @ret;

    my $structure = $core->get_structure();
    FRINGE 100, $S::LITERAL->build( { structure => $structure } );

    if ( my $rel = $core->get_underlying_reln() ) {
        FRINGE 50, $rel;
    }

    for my $category ( @{ $core->get_cats() } ) {
        next if $category eq $S::RELN_BASED;
        SLTM::SpikeBy( 5, $category );
        FRINGE 100, $category;

        my $bindings = $core->get_binding( $category );
        my $meto_mode = $bindings->get_metonymy_mode();
        if ($meto_mode ne $METO_MODE::NONE) {
            FRINGE 100, $meto_mode;
            FRINGE 100, $bindings->get_metonymy_type();
        }
    }

    return \@ret;
};

 <fringe>
     return get_fringe_for($core->GetEffectiveObject());
 </fringe>

 <actions>
    my $metonym            = $core->get_metonym();
    my $metonym_activeness = $core->get_metonym_activeness();

    # extendibility checking...
    if ( $core->get_right_extendibility() ) {

        #CODELET 100, AttemptExtension,
        #    { core => $core,
        #      direction => DIR::RIGHT(),
        #  };
        CODELET 100, AttemptExtensionOfGroup,
          {
            object    => $core,
            direction => DIR::RIGHT(),
          };
    }
    if ( $core->get_left_extendibility() ) {

        #CODELET 100, AttemptExtension,
        #    { core => $core,
        #      direction => DIR::LEFT(),
        #  };
        CODELET 100, AttemptExtensionOfGroup,
          {
            object    => $core,
            direction => DIR::LEFT(),
          };
    }

    if ( scalar(@$core) > 1 and SUtil::toss(0.8) ) {
        if ( SUtil::toss(0.5) ) {

            #main::message("Will launch ConvulseEnd");
            CODELET 100, ConvulseEnd,
              {
                object    => $core,
                direction => $DIR::RIGHT,
              };
        }
        else {

            #main::message("Will launch ConvulseEnd");
            CODELET 100, ConvulseEnd,
              {
                object    => $core,
                direction => $DIR::LEFT,
              };
        }
    }

    my $poss_cat;
    $poss_cat = $core->get_underlying_reln()->suggest_cat()
      if $core->get_underlying_reln;
    if ($poss_cat) {
        my $is_inst = $core->is_of_category_p($poss_cat)->[0];

        # main::message("$core is of $poss_cat? '$is_inst'");
        unless ($is_inst) {    #XXX if it already known, skip!
            CODELET 100, CheckIfInstance,
              {
                obj => $core,
                cat => $poss_cat
              };
        }

        if (    $Global::Feature{meto}
            and $S::IsMetonyable{$poss_cat}
            and not($metonym) )
        {
            CODELET 100, FindIfMetonyable,
              {
                object   => $core,
                category => $poss_cat,
              };
        }
    }

    my $possible_category_for_ends =
      $core->get_underlying_reln()->suggest_cat_for_ends()
      if $core->get_underlying_reln;
    if ($possible_category_for_ends) {
        for ( { $core->get_underlying_reln()->get_items() } ) {
            unless (UNIVERSAL::isa($_, "SAnchored")) {
                print "An item of an SAnchored object($core) is not anchored!\n";
                print "The anchored object is ", $core->get_structure_string(), "\n";
                print "Its items are: ", join("; ", @$core);
                confess "$_ is not anchored!" 
            }
            my $is_inst =
              $_->is_of_category_p($possible_category_for_ends)->[0];
            unless ($is_inst) {
                CODELET 100, CheckIfInstance,
                  {
                    obj => $_,
                    cat => $possible_category_for_ends
                  };
            }
        }
    }

 </actions>

##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::SElement
 [param] core!
 [param] magnitude
 [build] $magnitude_of{$id} = $core->get_mag();

 multimethod get_fringe_for => ('SElement') => sub {
     my ( $core ) = @_;
     my $mag = $core->get_mag();
     my @ret;

     FRINGE 100, $S::LITERAL->build( { structure => [$mag] });

     for (@{$core->get_categories()}) {
         next if $_ eq $S::RELN_BASED;
         FRINGE 80, $_;
     }
    
     my $abs_pos = "absolute_position_". $core->get_left_edge();
     FRINGE 80, $abs_pos;

     return \@ret;
 };

 <fringe>
     return get_fringe_for($core);
 </fringe>

 <extended_fringe>
     my $mag = $magnitude;
    
     FRINGE 50, $S::LITERAL->build( { structure => [ $mag + 1] });
     FRINGE 50, $S::LITERAL->build( { structure => [ $mag - 1] });

     my $pos = $core->get_left_edge();
     my $prev_abs_pos = "absolute_position_" . ($pos - 1);
     my $next_abs_pos = "absolute_position_" . ($pos + 1);
     FRINGE 80, $prev_abs_pos;
     FRINGE 80, $next_abs_pos;
 </extended_fringe>

 <actions>

 </actions>

##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::SReln_Compound
 [param] core!
 [params] base_cat, base_meto_mode, base_pos_mode
 [params] changed_bindings_of
 [params] metonymy_reln
 [multi] createRule

 <build>
     $base_cat_of{$id} = $core->get_base_category;
     $base_meto_mode_of{$id} = $core->get_base_meto_mode;
     $base_pos_mode_of{$id} = $core->get_base_pos_mode;
     $changed_bindings_of_of{$id} = $core->get_changed_bindings_ref;
     $metonymy_reln_of{$id} = $core->get_metonymy_reln;
 </build>

 <fringe>
     FRINGE 100, $base_cat;
     FRINGE 50, $core->get_first();
     FRINGE 50, $core->get_second();
 </fringe>

 <actions>

    my $holey = SWorkspace->are_there_holes_here( $core->get_ends );

    if ( not $holey ) {
        if ( $core->get_right_extendibility() eq $EXTENDIBILE::PERHAPS ) {
            ACTION 80, AttemptExtensionOfRelation,
              { core => $core, direction => $DIR::RIGHT };
        }
        if ( $core->get_left_extendibility() eq $EXTENDIBILE::PERHAPS ) {
            ACTION 80, AttemptExtensionOfRelation,
              { core => $core, direction => $DIR::LEFT };
        }
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
                ACTION 100, TryRule,
                  {
                    rule => $rule,
                    reln => $core,
                  };
            }
        }

    }

    {
        last unless $Global::Feature{interlaced};
        last unless $holey;
        my ( $l1, $r1, $l2, $r2 ) =
          map { $_->get_edges() } ( $core->get_first(), $core->get_second() );
        my @gap                 = ( min( $r1, $r2 ) + 1, max( $l1, $l2 ) - 1 );
        my @intervening_objects = SWorkspace->get_intervening_objects(@gap);
        my $distance            = scalar(@intervening_objects);
        last unless $distance;

        my $possible_ad_hoc_cat =
          $S::AD_HOC->build( { parts_count => $distance + 1 } );

        #main::message(Scalar::Util::refaddr($possible_ad_hoc_cat));
        SLTM::InsertUnlessPresent($possible_ad_hoc_cat);
        my $ad_hoc_activation =
          SLTM::SpikeBy( 5 / $distance, $possible_ad_hoc_cat );

      #main::message("ad_hoc(dis => $distance) activation: $ad_hoc_activation");

        if (    SUtil::significant($ad_hoc_activation)
            and SUtil::toss($ad_hoc_activation) )
        {
            my @ends =
              sort { $a->get_left_edge() <=> $b->get_left_edge() }
              ( $core->get_ends() );

# XXX(Board-it-up): [2006/11/16] Mysteriously, the next line fails.
#            my @ends = ikeysort { $_->get_left_edge() } ( $core->get_first(), $core->get_second() );
            my $new_obj = SAnchored->create( $ends[0], @intervening_objects );
            if (
                SWorkspace->get_all_groups_with_exact_span(
                    $new_obj->get_edges()
                )
              )
            {
                return;
            }

            SWorkspace->add_group($new_obj) or return;
            $new_obj->describe_as($possible_ad_hoc_cat);
        }

    }

 </actions>

##########################################
##########################################
  no Compile::SThought;
  use Compile::SThought;
  use Sort::Key qw(ikeysort);
  [package] SThought::SReln_Simple
  [param] core!
  [param] str
  [multi] createRule
  [build] $str_of{$id} = $core->get_text();
  <fringe>
    FRINGE 100, $str;
    FRINGE 50,  $core->get_first();
    FRINGE 50,  $core->get_second();
  </fringe>

  <actions>
    my $holey = SWorkspace->are_there_holes_here( $core->get_ends );

    if ( $str eq "same" ) {
        THOUGHT AreTheseGroupable,
          {
            items => [ $core->get_first(), $core->get_second(), ],
            reln  => $core,
          };
    }

    {
        last if $holey;
        CODELET 100, AttemptExtensionOfRelation,
          {
            core      => $core,
            direction => DIR::RIGHT()
          };
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
        last unless $Global::Feature{interlaced};
        last unless $holey;
        my ( $l1, $r1, $l2, $r2 ) =
          map { $_->get_edges() } ( $core->get_first(), $core->get_second() );
        my @gap                 = ( min( $r1, $r2 ) + 1, max( $l1, $l2 ) - 1 );
        my @intervening_objects = SWorkspace->get_intervening_objects(@gap);
        my $distance            = scalar(@intervening_objects);
        last unless $distance;

        my $possible_ad_hoc_cat =
          $S::AD_HOC->build( { parts_count => $distance + 1 } );

        #main::message(Scalar::Util::refaddr($possible_ad_hoc_cat));
        SLTM::InsertUnlessPresent($possible_ad_hoc_cat);
        my $ad_hoc_activation =
          SLTM::SpikeBy( 5 / $distance, $possible_ad_hoc_cat );

      #main::message("ad_hoc(dis => $distance) activation: $ad_hoc_activation");

        if (    SUtil::significant($ad_hoc_activation)
            and SUtil::toss($ad_hoc_activation) )
        {
            my @ends =
              ikeysort { $_->get_left_edge() }
            ( $core->get_first(), $core->get_second() );
            my $new_obj = SAnchored->create( $ends[0], @intervening_objects );
            if (
                SWorkspace->get_all_groups_with_exact_span(
                    $new_obj->get_edges()
                )
              )
            {
                return;
            }

            SWorkspace->add_group($new_obj);
            $new_obj->describe_as($possible_ad_hoc_cat);
        }

    }

  </actions>

##########################################
##########################################
  no Compile::SThought;
  use Compile::SThought;
  [package] SThought::ShouldIFlip
  [param] reln!
  <fringe>
  </fringe>

  <actions>
    #if this is part of a group, the answer is NO, don't flip!
    my ( $l, $r ) = $reln->get_extent();
    if ( SWorkspace->is_there_a_covering_group( $l, $r ) ) {
        return;
    }
    else {

        #okay, so we *may* switch... lets go ahead for now
        ACTION 100, flipReln, { reln => $reln };
    }
</actions>
 
1;

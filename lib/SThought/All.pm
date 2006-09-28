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

    if ($a_core and $b_core) {
        if ($a_core->isa("SObject") and $b_core->isa("SObject")) {
            ACTION 100, FindIfRelated,
                { a => $a_core,
                  b => $b_core
                      };
        } elsif ($a_core->isa("SReln") and $b_core->isa("SReln")) {
            ## I am comparing two relations!
            ACTION 100, FindIfRelatedRelns,
                { a => $a_core,
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
 [param] reln

 <fringe>
     foreach (@$items) {
         FRINGE 20, $_;
     }
 </fringe>

 <actions>
     # Check if these are already grouped...
     # to do that, we need to find the left and right edges
     my (@left_edges, @right_edges);
     for (@$items) {
         push @left_edges, $_->get_left_edge;
         push @right_edges, $_->get_right_edge;
     }
     my $left_edge  = min(@left_edges);
     my $right_edge = max(@right_edges);
     my $is_covering = SWorkspace->is_there_a_covering_group($left_edge,
                                                             $right_edge);
     return if $is_covering;

     my $new_group;
     eval { $new_group = SAnchored->create(@$items);
            if ($new_group){
                $new_group->set_underlying_reln($reln);
                return unless $new_group->describe_as( $S::RELN_BASED );
                SWorkspace->add_group($new_group);
            }

        };
     if (my $e = $EVAL_ERROR) {
         if (UNIVERSAL::isa($e, "SErr::HolesHere")) {
             return;
         } 
         die $e;
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
     my $gp = $group;
     my $span = $gp->get_span;
     my $total_count = $SWorkspace::elements_count;
     ### $span, $total_count
    
     if ($Global::AtLeastOneUserVerification and ($span / $total_count) > 0.8) {
         # This very well may be it!
         if ($gp->get_left_edge() != 0) {
             if ($gp->get_left_extendibility() ne EXTENDIBILE::NO()) {
                 ACTION 80, AttemptExtension,
                     { core => $gp,
                       direction => DIR::LEFT()
                           };
             } else {
                 if ($total_count - $span == $gp->get_left_edge) {
                     main::message("I believe this group has a blemish at the beginning");
                 }
             }
         } else {
             # so flush left
             if ($span == $total_count) {
                 #Bingo!
                 if ($gp->get_right_extendibility() ne EXTENDIBILE::NO()) {
                     #great. 
                     main::update_display();
                     BelieveDone();
                 } else {
                     main::update_display();
                     my $rejected = join(", ", keys %::EXTENSION_REJECTED_BY_USER);
                     my $msg = "I think I am stuck. ";
                     $msg .= "You have already rejected $rejected as possible continuation(s)";
                     main::message($msg);
                 }
             } else {
                 ACTION 80, AttemptExtension,
                     { core => $gp,
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


##########################################
##########################################
 no Compile::SThought;
 use Compile::SThought;
 [package] SThought::SAnchored
 [param] core!

 multimethod get_fringe_for => ('SAnchored') => sub {
     my ( $core ) = @_;
     my @ret;

     my $structure = $core->get_structure();
     FRINGE 100, $S::LITERAL->build( { structure => $structure });

     if (my $rel = $core->get_underlying_reln()) {
         FRINGE 50, $rel;
     }

     for (@{$core->get_cats()}) {
         next if $_ eq $S::RELN_BASED;
         FRINGE 100, $_;
     }

     return \@ret;
 };

 <fringe>
     return get_fringe_for($core->get_effective_object());
 </fringe>

 <actions>
     my $metonym = $core->get_metonym();
     my $metonym_activeness = $core->get_metonym_activeness();

     # extendibility checking...
     if ($core->get_right_extendibility()) {
         CODELET 100, AttemptExtension,
             { core => $core,
               direction => DIR::RIGHT(),
           };
     }
     if ($core->get_left_extendibility()) {
         CODELET 100, AttemptExtension,
             { core => $core,
               direction => DIR::LEFT(),
           };
     }

     my $poss_cat;
     $poss_cat = $core->get_underlying_reln()->suggest_cat() 
         if $core->get_underlying_reln;
     if ($poss_cat) {
         my $is_inst = $core->is_of_category_p($poss_cat)->[0];
         # main::message("$core is of $poss_cat? '$is_inst'");
         unless ($is_inst) { #XXX if it already known, skip!
             CODELET 100, CheckIfInstance,
                 {
                     obj => $core,
                     cat => $poss_cat
                         };
         }
         
         #if ($S::IsMetonyable{$poss_cat} and not($metonym)) {
         #    CODELET 100, FindIfMetonyable,
         #        { object => $core,
         #          category => $poss_cat,
         #      };
         # }
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
 [params] unchanged_bindings_of, changed_bindings_of
 [params] metonymy_reln

 <build>
     $base_cat_of{$id} = $core->get_base_category;
     $base_meto_mode_of{$id} = $core->get_base_meto_mode;
     $base_pos_mode_of{$id} = $core->get_base_pos_mode;
     $unchanged_bindings_of_of{$id} = $core->get_unchanged_bindings_ref;
     $changed_bindings_of_of{$id} = $core->get_changed_bindings_ref;
     $metonymy_reln_of{$id} = $core->get_metonymy_reln;
 </build>

 <fringe>
     FRINGE 100, $base_cat;
     FRINGE 50, $core->get_first();
     FRINGE 50, $core->get_second();
 </fringe>

 <actions>

 </actions>

##########################################
##########################################
  no Compile::SThought;
  use Compile::SThought;
  use Sort::Key qw(ikeysort);
  [package] SThought::SReln_Simple
  [param] core!
  [param] str
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
        CODELET 100, AttemptExtension,
            {
            core      => $core,
            direction => DIR::RIGHT()
            };
    }

    {
        last unless $holey;
        my ( $l1, $r1, $l2, $r2 )
            = map { $_->get_edges() } ( $core->get_first(), $core->get_second() );
        my @gap                 = ( min( $r1, $r2 ) + 1, max( $l1, $l2 ) - 1 );
        my @intervening_objects = SWorkspace->get_intervening_objects(@gap);
        my $distance            = scalar(@intervening_objects);

        if ( $distance == 1 ) {    # Cheat? create an ad hoc gp...
            my @ends = ikeysort { $_->get_left_edge() } ( $core->get_first(), $core->get_second() );
            my $new_obj = SAnchored->create( $ends[0], @intervening_objects );
            if ( SWorkspace->get_all_groups_with_exact_span( $new_obj->get_edges() ) ) {
                return;
            }
            SWorkspace->add_group($new_obj);
            $new_obj->describe_as( $S::AD_HOC->build( { parts_count => 2 } ) );

            #main::message("The relation has a gap: @gap; distance = $distance");

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
      my ($l, $r) = $reln->get_extent();
      if (SWorkspace->is_there_a_covering_group($l, $r)) {
          return;
      } else {
          #okay, so we *may* switch... lets go ahead for now
          ACTION 100, flipReln, { reln => $reln };
      }
  </actions>
 
1;

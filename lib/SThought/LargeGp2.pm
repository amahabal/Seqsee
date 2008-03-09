CodeletFamily LargeGroup( $group ! ) does {
RUN: {
        my $flush_right = $group->IsFlushRight();
        my $flush_left  = $group->IsFlushLeft();

        if ( $flush_right and $flush_left ) {
            CODELET 100, AreWeDone, { group => $group };
        }
        elsif ( $Global::AtLeastOneUserVerification and $flush_right and !$flush_left ) {
            CODELET 100,  MaybeStartBlemish, { group => $group };
        }
    }
}

CodeletFamily MaybeStartBlemish( $group ! ) does {
RUN: {
        #XXX runs too eagerly.
        my $flush_right = $group->IsFlushRight();
        my $flush_left  = $group->IsFlushLeft();
        if ( !$flush_left ) {
            my $extension = $group->FindExtension( $DIR::LEFT, 0 );
            if ($extension) {
                $group->Extend($extension, 0);
            }
            else {
                # So there *is* a blemish!
                #main::message("Start Blemish?");
                my $underlying_ruleapp = $group->get_underlying_reln() or return;
                my $underlying_rule = $underlying_ruleapp->get_rule();
                my $transform = $underlying_rule->get_transform();

                if ( $transform->isa("Transform::Structural") ) {
                    my $cat = $transform->get_category();
                    #main::message($cat->get_name());
                    if ( $cat->get_name() =~ m#^Interlaced_(.*)#o ) {
                        CODELET 100, InterlacedInitialBlemish,
                            {
                                count => $1,
                                group => $group,
                                cat   => $cat,
                            };
                        return;
                    }
                }

                # So: either statecount > 1, or not interlaced.
                if ($flush_right) {
                    CODELET 100, ArbitraryInitialBlemish, { group => $group };
                }
            }
        }
    }
}

CodeletFamily InterlacedInitialBlemish( $count !, $group !, $cat ! ) does {
RUN: {
        return unless SWorkspace::__CheckLiveness($group);
        my @parts = @$group;
        Global::Hilit(1, @parts);
        main::message(
            "I realize that there are $count interlaced groups in the sequence, and I have started on the wrong foot. I will shift the big group one unit, and see if that helps!!"
        );
        Global::ClearHilit();
        my @subparts = map {@$_} @parts;
        SWorkspace::__DeleteGroup($group);
        SWorkspace::__DeleteGroup($_) for @parts;
        shift(@subparts);
        my @newparts;
        while ( @subparts > $count ) {
            my @new_part;
            for ( 1 .. $count ) {
                push @new_part, shift(@subparts);
            }
            my $newpart = SAnchored->create(@new_part);
            $newpart->describe_as($cat);
            SWorkspace->add_group($newpart) or return;
            push @newparts, $newpart;
        }
        my $new_gp = SAnchored->create(@newparts);
        SWorkspace->add_group($new_gp);
        ContinueWith(SThought->create($new_gp));
    }
}

CodeletFamily ArbitraryInitialBlemish( $group ! ) does {
RUN: {
        SErr::FinishedTestBlemished->throw() if $Global::TestingMode;
        ACTION 100, DescribeSolution, { group => $group };
    }
}

1;

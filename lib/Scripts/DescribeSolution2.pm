CodeletFamily DescribeSolution( $group ! ) does scripted {
  NAME: {Describe Solution}
STEP: {
        my $ruleapp = $group->get_underlying_reln();
        unless ($ruleapp) {
            RETURN;
        }
        my $rule = $ruleapp->get_rule;
        my $position_structure = PositionStructure->Create($group);
        if (SolutionConfirmation->HasThisBeenRejected($rule, $position_structure)) {
            # main::message("There is a rule I like. Alas, it has been rejected!");
            RETURN;
        }
}
STEP: {
        if ( my $ruleapp = $group->get_underlying_reln() ) {
            SWorkspace::DeleteObjectsInconsistentWith($ruleapp);
        }
        main::message( "I will describe the solution now!", 1 );
        SCRIPT DescribeInitialBlemish, { group => $group };
    }
STEP: {
        SCRIPT DescribeBlocks, { group => $group };
    }

STEP: {
        my $ruleapp = $group->get_underlying_reln();
        my $rule    = $ruleapp->get_rule();
        SCRIPT DescribeRule, { rule => $rule, ruleapp => $ruleapp };
    }

STEP: {
        SLTM->Dump('memory_dump.dat') if $Global::Feature{LTM};
    }
STEP: {
        main::message("That finishes the description!", 1);
    }
STEP: {
        my $response = $SGUI::Commentary->MessageRequiringAResponse(
            ['Yes', 'No'],
            "Does this generate the sequence you had in mind?"
                );
        my $rule = $group->get_underlying_reln()->get_rule();
        my $group_position = PositionStructure->Create($group);
        # main::message("That response corresponded to $rule and group at $group_position");
        if ($response eq 'Yes') {
            SolutionConfirmation->SetAcceptedSolution($rule, $group_position);
        } else {
            SolutionConfirmation->AddRejectedSolution($rule, $group_position);
        }
    }
}

CodeletFamily DescribeInitialBlemish( $group ! ) does scripted {
STEP: {
        if ( my $le = $group->get_left_edge() ) {
            my @initial_bl = map { $_->get_mag() } ( SWorkspace::GetElements() )[ 0 .. $le - 1 ];
            main::message(
                'There is an initial blemish in the sequence: ' . join( ', ', @initial_bl )
                    . (
                    scalar(@initial_bl) > 1
                    ? ' don\'t fit'
                    : ' doesn\'t fit'
                    ),
                1
            );
        }

        RETURN;
    }
}

CodeletFamily DescribeBlocks( $group ! ) does scripted {
STEP: {
        my @parts = @$group;
        my $msg = join( '; ', map { $_->get_structure_string() } @parts );
        main::message( "The sequence consists of the blocks $msg", 1 );
        RETURN;
    }
}

CodeletFamily DescribeRule( $rule !, $ruleapp ! ) does scripted {
STEP: {
        main::debug_message( "Rule is $rule", 1 );
        my $reln = $rule->get_transform;
        SCRIPT DescribeTransform, { reln => $reln, ruleapp => $ruleapp };
        Global::SetRuleAppAsBest($ruleapp);
    }
STEP: {
        RETURN;
    }
}

CodeletFamily DescribeTransform ( $reln !, $ruleapp = {0} ) does scripted {
STEP: {
        if ( $reln->isa('Transform::Structural') ) {
            SCRIPT DescribeRelationCompound, { reln => $reln, ruleapp => $ruleapp };
        }
        elsif ( $reln->isa('Transform::Numeric') ) {
            SCRIPT DescribeRelationSimple, { reln => $reln };
        }
        else {
            main::message( "Strange bond! Something wrong, let abhijit know", 1 );
        }
    }
}

CodeletFamily DescribeRelationSimple( $reln ! ) does scripted {
STEP: {
        my $string = $reln->get_name();
        my $msg    = 'Each succesive term is the ';
        if ( $string eq 'succ' ) {
            $msg .= 'successor ';
        }
        elsif ( $string eq 'pred' ) {
            $msg .= 'predecessor ';
        }
        elsif ( $string eq 'same' ) {
            $msg .= 'same as ';
        }
        my $cat  = $reln->get_category() ;
        if ($cat eq $S::NUMBER or $string eq 'same') {
            $msg .= 'the previous term';
        }  else {
            $msg .=  "the previous term seen as a " . $cat->get_name();
        }
       
        main::message( $msg, 1 );
    }
}

CodeletFamily DescribeRelationCompound( $reln !, $ruleapp ! ) does scripted {
STEP: {
        my $category = $reln->get_category();
        SCRIPT DescribeRelnCategory, { cat => $category };
    }
STEP: {
        my $meto_mode = $reln->get_meto_mode();
        my $meto_reln = $reln->get_metonymy_reln();
        SCRIPT DescribeRelnMetoMode,
            {
            meto_mode => $meto_mode,
            meto_reln => $meto_reln,
            ruleapp   => $ruleapp,
            };
    }
}

CodeletFamily DescribeRelnCategory( $cat ! ) does scripted {
STEP: {
        my $name = $cat->get_name();
        main::message(
            "Each block is an instance of $name. (Better descriptions of categories will be implemented)",
            1
        );
    }
}

CodeletFamily DescribeRelnMetoMode( $meto_mode !, $meto_reln !, $ruleapp ! ) does scripted {
STEP: {
        unless ( $meto_mode->is_metonymy_present ) {
            RETURN;
        }

        main::message( 'I am squinting in order to see the blocks as instances of that category',
            1 );
        my @items = @{ $ruleapp->get_items() };
        my @to_describe = ( scalar(@items) > 3 ) ? ( @items[ 0 .. 2 ] ) : @items;
        main::message( 'I am seeing: ', 1 );
        for (@to_describe) {
            my $msg = "\t"
                . $_->get_structure_string()
                . ' is being seen as '
                . $_->GetEffectiveStructureString();
            main::message( $msg, 1 );
        }
        main::message( "\t\t... and so forth", 1 );
    }
}

1;

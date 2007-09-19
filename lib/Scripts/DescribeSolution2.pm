CodeletFamily DescribeSolution( $group ! ) does scripted {
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

#STEP: {
#        SLTM->Dump('memory_dump.dat');
#    }

STEP: {
        main::message("That finishes the description!");
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
        my $state_count = $rule->get_state_count();
        main::debug_message( "Rule is $rule", 1 );
        if ( $state_count > 1 ) {
            main::message( "Complex rule display not implemented", 1 );
            RETURN;
        }
        else {
            my $reln = $rule->get_relations()->[0];
            SCRIPT DescribeRelation, { reln => $reln, ruleapp => $ruleapp };
        }
        Global::SetRuleAppAsBest($ruleapp);
    }
STEP: {
        RETURN;
    }
}

CodeletFamily DescribeRelation( $reln !, $ruleapp = {0} ) does scripted {
STEP: {
        if ( $reln->isa('SRelnType::Compound') ) {
            SCRIPT DescribeRelationCompound, { reln => $reln, ruleapp => $ruleapp };
        }
        elsif ( $reln->isa('SRelnType::Simple') ) {
            SCRIPT DescribeRelationSimple, { reln => $reln };
        }
        else {
            main::message( "Strange bond! Something wrong, let abhijit know", 1 );
        }
    }
}

CodeletFamily DescribeRelationSimple( $reln ! ) does scripted {
STEP: {
        my $string = $reln->get_text();
        my $msg    = 'Each succesive term is the ';
        if ( $string eq 'succ' ) {
            $msg .= 'numerical successor ';
        }
        elsif ( $string eq 'pred' ) {
            $msg .= 'numerical predecessor ';
        }
        elsif ( $string eq 'same' ) {
            $msg .= 'same as ';
        }
        $msg .= 'the previous term';
        main::message( $msg, 1 );
    }
}

CodeletFamily DescribeRelationCompound( $reln !, $ruleapp ! ) does scripted {
STEP: {
        my $category = $reln->get_base_category();
        SCRIPT DescribeRelnCategory, { cat => $category };
    }
STEP: {
        my $meto_mode = $reln->get_base_meto_mode();
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

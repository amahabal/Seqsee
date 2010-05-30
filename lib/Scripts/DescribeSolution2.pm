CodeletFamily DescribeSolution( $group! ) does scripted {
  NAME: { Describe Solution }
  STEP: {
    my $ruleapp = $group->get_underlying_reln();
    unless ($ruleapp) {
      RETURN;
    }
    my $rule               = $ruleapp->get_rule;
    my $position_structure = PositionStructure->Create($group);
    if (
      SolutionConfirmation->HasThisBeenRejected( $rule, $position_structure ) )
    {

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
    main::message( "That finishes the description!", 1 );
  }
  STEP: {
    my $response =
    $SGUI::Commentary->MessageRequiringAResponse( [ 'Yes', 'No' ],
      "Does this generate the sequence you had in mind?" );
    my $rule           = $group->get_underlying_reln()->get_rule();
    my $group_position = PositionStructure->Create($group);

# main::message("That response corresponded to $rule and group at $group_position");
    if ( $response eq 'Yes' ) {
      SolutionConfirmation->SetAcceptedSolution( $rule, $group_position );
    }
    else {
      SolutionConfirmation->AddRejectedSolution( $rule, $group_position );
    }
  }
}

CodeletFamily DescribeInitialBlemish( $group! ) does scripted {
  NAME: { Describe Initial Blemish }
  STEP: {
    if ( my $le = $group->get_left_edge() ) {
      my @initial_bl =
      map { $_->get_mag() } ( SWorkspace::GetElements() )[ 0 .. $le - 1 ];
      main::message(
        'There is an initial blemish in the sequence: '
        . join( ', ', @initial_bl )
        . (
          scalar(@initial_bl) > 1
          ? ' don\'t fit'
          :' doesn\'t fit'
        ),
        1
      );
    }

    RETURN;
  }
}

CodeletFamily DescribeBlocks( $group! ) does scripted {
  NAME: { Describe Groups }
  STEP: {
    my @parts = @$group;
    my $msg = join( '; ', map { $_->get_structure_string() } @parts );
    main::message( "The sequence consists of the blocks $msg", 1 );
    RETURN;
  }
}

CodeletFamily DescribeRule( $rule!, $ruleapp! ) does scripted {
  NAME: { Describe Rule }
  STEP: {
    main::debug_message( "Rule is $rule", 1 );
    my $reln = $rule->get_transform;
    SCRIPT DescribeMapping, { reln => $reln, ruleapp => $ruleapp };
    Global::SetRuleAppAsBest($ruleapp);
  }
  STEP: {
    RETURN;
  }
}

CodeletFamily DescribeMapping( $reln!, $ruleapp = {0} ) does scripted {
  NAME: { Describe Analogy Between Groups }
  STEP: {
    if ( $reln->isa('Mapping::Structural') ) {
      SCRIPT DescribeRelationCompound, { reln => $reln, ruleapp => $ruleapp };
    }
    elsif ( $reln->isa('Mapping::Numeric') ) {
      SCRIPT DescribeRelationSimple, { reln => $reln };
    }
    else {
      main::message( "Strange bond! Something wrong, let abhijit know", 1 );
    }
  }
}

CodeletFamily DescribeRelationSimple( $reln! ) does scripted {
  NAME: { Describe Simple Analogy }
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
    my $cat = $reln->get_category();
    if ( $cat eq $S::NUMBER or $string eq 'same' ) {
      $msg .= 'the previous term';
    }
    else {
      $msg .= "the previous term seen as a " . $cat->get_name();
    }

    main::message( $msg, 1 );
  }
}

CodeletFamily DescribeRelationCompound( $reln!, $ruleapp! ) does scripted {
  NAME: { Describe Compound Analogy }
  STEP: {
    my $category = $reln->get_category();
    SCRIPT DescribeRelnCategory,
    {
      cat     => $category,
      ruleapp => $ruleapp,
    };
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

CodeletFamily DescribeRelnCategory( $cat!, $ruleapp! ) does scripted {
  NAME: { Describe Category on which Analogy is Based }
  STEP: {
    if ( $cat->isa('SCategory::Interlaced') ) {
      SCRIPT DescribeInterlacedCategory,
      {
        cat     => $cat,
        ruleapp => $ruleapp,
      };
    }
    else {

      my $name = $cat->get_name();
      main::message(
        "Each block is an instance of $name. (Better descriptions of categories will be implemented)",
        1
      );
    }
  }
}

CodeletFamily DescribeInterlacedCategory( $cat!, $ruleapp! ) does scripted {
  NAME: { Describe Interlaced Category }
  STEP: {
    my $parts = $cat->get_parts_count();
    if ( $parts == 2 ) {
      SCRIPT Describe2InterlacedCategory,
      {
        cat     => $cat,
        ruleapp => $ruleapp,
      };
    }
    else {
      SCRIPT DescribeMultipleInterlacedCategory,
      {
        cat     => $cat,
        ruleapp => $ruleapp,
      };
    }
  }
}

CodeletFamily Describe2InterlacedCategory( $cat!, $ruleapp! ) does scripted {
  NAME: { Describe a Two-Interlaced-Sequences Category }
  STEP: {
    my @items        = @{ $ruleapp->get_items() };
    my @first_items  = map { $_->[0] } @items;
    my @second_items = map { $_->[1] } @items;

    @first_items  = @first_items[ 0 .. 2 ]  if @first_items > 3;
    @second_items = @second_items[ 0 .. 2 ] if @second_items > 3;

    my $msg               = "The group is thus made up of a size-2 template. ";
    my @first_categories  = Categorizable::get_common_categories(@first_items);
    my @second_categories = Categorizable::get_common_categories(@second_items);

    if (@first_categories) {
      $msg .=
      "An instance of the first item in the template is an instance of '"
      . $first_categories[0]->as_text() . "'. ";
      if ( @first_categories > 1 ) {
        $msg .= " and also of the categories ";
        $msg .= join( q{, },
          map { q{'} . $_->as_text . q{'} }
          @first_categories[ 2 .. $#first_categories ] );
        $msg .= q{. };
      }
    }

    if (@second_categories) {
      $msg .= "The second item in the template is an instance of '"
      . $second_categories[0]->as_text() . "'. ";
      if ( @second_categories > 1 ) {
        $msg .= " and also of the categories ";
        $msg .= join( q{, },
          map { q{'} . $_->as_text . q{'} }
          @second_categories[ 2 .. $#second_categories ] );
        $msg .= q{. };
      }
    }

    $msg .=
    "The sequence can also be thought as consisting of two interlaced sequences. Seen this way, the first of these interlaced groups consists of "
    . join( ", ", map { $_->get_structure_string() } @first_items )
    . " and so forth, whereas the second consists of "
    . join( ", ", map { $_->get_structure_string() } @second_items )
    . " and so forth.";
    main::message( $msg, 1 );
  }
}

CodeletFamily DescribeMultipleInterlacedCategory( $cat!, $ruleapp! ) does
scripted {
  NAME: { Describe a Multiple-Interlaced-Sequences Category }
  STEP: {
    my @items        = @{ $ruleapp->get_items() };
    my @first_items  = map { $_->[0] } @items;
    my @second_items = map { $_->[1] } @items;

    @first_items  = @first_items[ 0 .. 2 ]  if @first_items > 3;
    @second_items = @second_items[ 0 .. 2 ] if @second_items > 3;

    my $count = $cat->get_parts_count();
    my $msg =
    "The sequence consists of $count interlaced sequences. The first of these consists of "
    . join( ", ", map { $_->get_structure_string() } @first_items )
    . " and so forth, and the second of these $count sequences consists of "
    . join( ", ", map { $_->get_structure_string() } @second_items )
    . " and so forth.";
    main::message( $msg, 1 );
  }
}

CodeletFamily DescribeRelnMetoMode( $meto_mode!, $meto_reln!, $ruleapp! ) does
scripted {
  NAME: { Describe Change in Squinting }
  STEP: {
    unless ( $meto_mode->is_metonymy_present ) {
      RETURN;
    }

    main::message(
      'I am squinting in order to see the blocks as instances of that category',
      1
    );
    my @items = @{ $ruleapp->get_items() };
    my @to_describe = ( scalar(@items) > 3 ) ? ( @items[ 0 .. 2 ] ) :@items;
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

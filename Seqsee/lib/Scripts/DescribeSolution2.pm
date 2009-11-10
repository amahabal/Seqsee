{

  package SCF::DescribeSolution;
  our $package_name_ = 'DescribeSolution';
  our $NAME          = 'Describe Solution';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $group = $opts_ref->{group}
    // confess "Needed 'group', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      my $ruleapp = $group->get_underlying_reln();
      unless ($ruleapp) {

        {
          my @new_stack = @$stack;
          return unless @new_stack;
          my $top_frame = pop(@new_stack);
          my ( $step_no, $args, $name ) = @$top_frame;
          SCodelet->new(
            $name, 10000,
            {
              __S_T_E_P__   => $step_no,
              __A_R_G_S__   => $args,
              __S_T_A_C_K__ => \@new_stack,
            }
          )->schedule();
          return;
        }
      }
      my $rule               = $ruleapp->get_rule;
      my $position_structure = PositionStructure->Create($group);
      if (
        SolutionConfirmation->HasThisBeenRejected( $rule, $position_structure )
      )
      {

        # main::message("There is a rule I like. Alas, it has been rejected!");

        {
          my @new_stack = @$stack;
          return unless @new_stack;
          my $top_frame = pop(@new_stack);
          my ( $step_no, $args, $name ) = @$top_frame;
          SCodelet->new(
            $name, 10000,
            {
              __S_T_E_P__   => $step_no,
              __A_R_G_S__   => $args,
              __S_T_A_C_K__ => \@new_stack,
            }
          )->schedule();
          return;
        }
      }
      $step_++;
    }
    if ( $step_ == 2 ) {
      if ( my $ruleapp = $group->get_underlying_reln() ) {
        SWorkspace::DeleteObjectsInconsistentWith($ruleapp);
      }
      main::message( "I will describe the solution now!", 1 );

      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeInitialBlemish',
          10000,
          {
            __S_T_E_P__   => 1,
            __A_R_G_S__   => { group => $group },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 3 ) {
      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeBlocks',
          10000,
          {
            __S_T_E_P__   => 1,
            __A_R_G_S__   => { group => $group },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 4 ) {
      my $ruleapp = $group->get_underlying_reln();
      my $rule    = $ruleapp->get_rule();

      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeRule',
          10000,
          {
            __S_T_E_P__   => 1,
            __A_R_G_S__   => { rule => $rule, ruleapp => $ruleapp },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 5 ) {
      SLTM->Dump('memory_dump.dat') if $Global::Feature{LTM};
      $step_++;
    }
    if ( $step_ == 6 ) {
      main::message( "That finishes the description!", 1 );
      $step_++;
    }
    if ( $step_ == 7 ) {
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
      $step_++;
    }
    if ( $step_ == 8 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeInitialBlemish;
  our $package_name_ = 'DescribeInitialBlemish';
  our $NAME          = 'Describe Initial Blemish';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $group = $opts_ref->{group}
    // confess "Needed 'group', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
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

      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeBlocks;
  our $package_name_ = 'DescribeBlocks';
  our $NAME          = 'Describe Groups';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $group = $opts_ref->{group}
    // confess "Needed 'group', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      my @parts = @$group;
      my $msg = join( '; ', map { $_->get_structure_string() } @parts );
      main::message( "The sequence consists of the blocks $msg", 1 );

      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeRule;
  our $package_name_ = 'DescribeRule';
  our $NAME          = 'Describe Rule';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $rule = $opts_ref->{rule}
    // confess "Needed 'rule', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      main::debug_message( "Rule is $rule", 1 );
      my $reln = $rule->get_transform;

      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeTransform',
          10000,
          {
            __S_T_E_P__   => 1,
            __A_R_G_S__   => { reln => $reln, ruleapp => $ruleapp },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      Global::SetRuleAppAsBest($ruleapp);
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 3 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeTransform;
  our $package_name_ = 'DescribeTransform';
  our $NAME          = 'Describe Analogy Between Groups';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $reln = $opts_ref->{reln}
    // confess "Needed 'reln', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp} // 0;

    if ( $step_ == 1 ) {
      if ( $reln->isa('Transform::Structural') ) {

        {
          my $new_stack =
          [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
          SCodelet->new(
            'DescribeRelationCompound',
            10000,
            {
              __S_T_E_P__   => 1,
              __A_R_G_S__   => { reln => $reln, ruleapp => $ruleapp },
              __S_T_A_C_K__ => $new_stack
            }
          )->schedule();
          return;
        };
      }
      elsif ( $reln->isa('Transform::Numeric') ) {

        {
          my $new_stack =
          [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
          SCodelet->new(
            'DescribeRelationSimple',
            10000,
            {
              __S_T_E_P__   => 1,
              __A_R_G_S__   => { reln => $reln },
              __S_T_A_C_K__ => $new_stack
            }
          )->schedule();
          return;
        };
      }
      else {
        main::message( "Strange bond! Something wrong, let abhijit know", 1 );
      }
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeRelationSimple;
  our $package_name_ = 'DescribeRelationSimple';
  our $NAME          = 'Describe Simple Analogy';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $reln = $opts_ref->{reln}
    // confess "Needed 'reln', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
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
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeRelationCompound;
  our $package_name_ = 'DescribeRelationCompound';
  our $NAME          = 'Describe Compound Analogy';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $reln = $opts_ref->{reln}
    // confess "Needed 'reln', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      my $category = $reln->get_category();

      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeRelnCategory',
          10000,
          {
            __S_T_E_P__ => 1,
            __A_R_G_S__ => {
              cat     => $category,
              ruleapp => $ruleapp,
            },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 2 ) {
      my $meto_mode = $reln->get_meto_mode();
      my $meto_reln = $reln->get_metonymy_reln();

      {
        my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
        SCodelet->new(
          'DescribeRelnMetoMode',
          10000,
          {
            __S_T_E_P__ => 1,
            __A_R_G_S__ => {
              meto_mode => $meto_mode,
              meto_reln => $meto_reln,
              ruleapp   => $ruleapp,
            },
            __S_T_A_C_K__ => $new_stack
          }
        )->schedule();
        return;
      };
      $step_++;
    }
    if ( $step_ == 3 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeRelnCategory;
  our $package_name_ = 'DescribeRelnCategory';
  our $NAME          = 'Describe Category on which Analogy is Based';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $cat = $opts_ref->{cat}
    // confess "Needed 'cat', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      if ( $cat->isa('SCat::OfObj::Interlaced') ) {

        {
          my $new_stack =
          [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
          SCodelet->new(
            'DescribeInterlacedCategory',
            10000,
            {
              __S_T_E_P__ => 1,
              __A_R_G_S__ => {
                cat     => $cat,
                ruleapp => $ruleapp,
              },
              __S_T_A_C_K__ => $new_stack
            }
          )->schedule();
          return;
        };
      }
      else {

        my $name = $cat->get_name();
        main::message(
          "Each block is an instance of $name. (Better descriptions of categories will be implemented)",
          1
        );
      }
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeInterlacedCategory;
  our $package_name_ = 'DescribeInterlacedCategory';
  our $NAME          = 'Describe Interlaced Category';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $cat = $opts_ref->{cat}
    // confess "Needed 'cat', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      my $parts = $cat->get_parts_count();
      if ( $parts == 2 ) {

        {
          my $new_stack =
          [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
          SCodelet->new(
            'Describe2InterlacedCategory',
            10000,
            {
              __S_T_E_P__ => 1,
              __A_R_G_S__ => {
                cat     => $cat,
                ruleapp => $ruleapp,
              },
              __S_T_A_C_K__ => $new_stack
            }
          )->schedule();
          return;
        };
      }
      else {

        {
          my $new_stack =
          [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
          SCodelet->new(
            'DescribeMultipleInterlacedCategory',
            10000,
            {
              __S_T_E_P__ => 1,
              __A_R_G_S__ => {
                cat     => $cat,
                ruleapp => $ruleapp,
              },
              __S_T_A_C_K__ => $new_stack
            }
          )->schedule();
          return;
        };
      }
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::Describe2InterlacedCategory;
  our $package_name_ = 'Describe2InterlacedCategory';
  our $NAME          = 'Describe a Two-Interlaced-Sequences Category';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $cat = $opts_ref->{cat}
    // confess "Needed 'cat', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      my @items        = @{ $ruleapp->get_items() };
      my @first_items  = map { $_->[0] } @items;
      my @second_items = map { $_->[1] } @items;

      @first_items  = @first_items[ 0 .. 2 ]  if @first_items > 3;
      @second_items = @second_items[ 0 .. 2 ] if @second_items > 3;

      my $msg              = "The group is thus made up of a size-2 template. ";
      my @first_categories = SInstance::get_common_categories(@first_items);
      my @second_categories = SInstance::get_common_categories(@second_items);

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
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeMultipleInterlacedCategory;
  our $package_name_ = 'DescribeMultipleInterlacedCategory';
  our $NAME          = 'Describe a Multiple-Interlaced-Sequences Category';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $cat = $opts_ref->{cat}
    // confess "Needed 'cat', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
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
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

{

  package SCF::DescribeRelnMetoMode;
  our $package_name_ = 'DescribeRelnMetoMode';
  our $NAME          = 'Describe Change in Squinting';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $args_ref ) = @_;

    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {

      # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = (
        $args_ref->{__S_T_A_C_K__},
        $args_ref->{__S_T_E_P__},
        $args_ref->{__A_R_G_S__}
      );
    }
    else {

      # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
      ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
    my $meto_mode = $opts_ref->{meto_mode}
    // confess "Needed 'meto_mode', only got " . join( ';', keys %$opts_ref );
    my $meto_reln = $opts_ref->{meto_reln}
    // confess "Needed 'meto_reln', only got " . join( ';', keys %$opts_ref );
    my $ruleapp = $opts_ref->{ruleapp}
    // confess "Needed 'ruleapp', only got " . join( ';', keys %$opts_ref );

    if ( $step_ == 1 ) {
      unless ( $meto_mode->is_metonymy_present ) {

        {
          my @new_stack = @$stack;
          return unless @new_stack;
          my $top_frame = pop(@new_stack);
          my ( $step_no, $args, $name ) = @$top_frame;
          SCodelet->new(
            $name, 10000,
            {
              __S_T_E_P__   => $step_no,
              __A_R_G_S__   => $args,
              __S_T_A_C_K__ => \@new_stack,
            }
          )->schedule();
          return;
        }
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
      $step_++;
    }
    if ( $step_ == 2 ) {
      {
        my @new_stack = @$stack;
        return unless @new_stack;
        my $top_frame = pop(@new_stack);
        my ( $step_no, $args, $name ) = @$top_frame;
        SCodelet->new(
          $name, 10000,
          {
            __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
          }
        )->schedule();
        return;
      };
      $step_++;
    }
  }

  # end run

  1;
}    # end surrounding

1;

package SCF::DescribeSolution;
use 5.010;
use Moose;
use MooseX::ClassAttribute;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;
use MooseX::Params::Validate;

extends 'Scripts';

my $package_name_ = "DescribeSolution";

class_has step => (
  traits => ['Array'],
  is        => 'ro',
  isa       => 'ArrayRef',
  default   => sub { [
    sub {
      my ($group) = @_;
      print "GROUP: $group\n";
      my $ruleapp = $group->get_underlying_reln();
      unless ($ruleapp) {
        print "Returning\n";
        RETURN();
      }
      my $rule               = $ruleapp->get_rule;
      my $position_structure = PositionStructure->Create($group);
      if (
        SolutionConfirmation->HasThisBeenRejected( $rule, $position_structure ) )
      {
        RETURN();
      }
      say "Reached end!";
    },
    sub {
      my ($group) = @_;
      if ( my $ruleapp = $group->get_underlying_reln() ) {
        SWorkspace::DeleteObjectsInconsistentWith($ruleapp);
      }
      main::message( "I will describe the solution now!", 1 );
      Scripts::SCRIPT('DescribeInitialBlemish', { group => $group });
    },
    sub {
      my ($group) = @_;
      Scripts::SCRIPT('DescribeBlocks', { group => $group });
    },
    sub {
      my ($group) = @_;
      my $ruleapp = $group->get_underlying_reln();
      my $rule    = $ruleapp->get_rule();
      Scripts::SCRIPT('DescribeRule', { rule => $rule, ruleapp => $ruleapp });
    },
    sub {
      my ($group) = @_;
      SLTM->Dump('memory_dump.dat') if $Global::Feature{LTM};
    },
    sub {
      my ($group) = @_;
      main::message( "That finishes the description!", 1 );
    },
    sub {
      my ($group) = @_;
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
    },
  ] },
  handles => {
    get_step => 'get',
    number_of_steps => 'count',
  }
);

class_has attributes => (
  traits => ['Array'],
  is        => 'ro',
  isa       => 'ArrayRef',
  default   => sub { [group => {}] },
  handles => {
    expected_attributes => 'elements',
  }
);

sub run {
  my ( $action_object, $args_ref ) = @_;
  
  # args_ref may or may not have any information about this being a script.
  # If it does not, it defaults to doing the first step...
  my ( $stack, $step_, $opts_ref );
  if ( exists $args_ref->{__S_T_A_C_K__} ) {
    ( $stack, $step_, $opts_ref ) = (
      $args_ref->{__S_T_A_C_K__},
      $args_ref->{__S_T_E_P__},
      $args_ref->{__A_R_G_S__}
    );
  }
  else {
    ( $stack, $step_, $opts_ref ) = ( [], 0, $args_ref );
  }

  # Validate arguments...
  my @arguments = validated_list( [ %{ $opts_ref } ], __PACKAGE__->expected_attributes() );

  while ($step_ < __PACKAGE__->number_of_steps()) {
    my $step = __PACKAGE__->get_step($step_);
  
    # Let's do the step. It may throw an exception, however, asking us to return from this codelet without
    # doing further steps.
    eval { print "Step#: $step_; $step==>@arguments\n"; $step->(@arguments) };
    my $e;
    # catch
    if ( $e = Exception::Class->caught('SErr::ScriptReturn') ) {
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
    } elsif ( $e = Exception::Class->caught('SErr::CallSubscript') ) {
      my $new_stack = [ @$stack, [ $step_ + 1, $opts_ref, $package_name_ ] ];
      my ($name, $arguments) = ($e->name(), $e->arguments());
      say "SUBSCRIPT: $name, $arguments";
      SCodelet->new(
        $name,
        10000,
        {
          __S_T_E_P__   => 1,
          __A_R_G_S__   => $arguments,
          __S_T_A_C_K__ => $new_stack
        }
      )->schedule();
      return;  
    } elsif ($e = Exception::Class->caught()) {
        ref $e ? $e->rethrow : die $e;
    }
    $step_++;
  }
}
__PACKAGE__->meta->make_immutable;


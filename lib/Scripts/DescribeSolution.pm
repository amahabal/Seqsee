package SCF::DescribeSolution;
use 5.010;
use Moose;
use MooseX::ClassAttribute;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;
use MooseX::Params::Validate;
use Scripts;

extends 'Scripts';
before 'run' => sub {};

class_has '+step' => (
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
                      );

class_has '+attributes' => (
  default   => sub { [group => {}] },
);


__PACKAGE__->meta->make_immutable;


package SCF::MaybeAskTheseTerms;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;

multimethod 'createRule';

Codelet_Family(
  attributes => [core => {}, exception => {}],
  body => sub {
    my ($core, $exception) = @_;
    main::message("MaybeAskTheseTerms called");
    my ( $type_of_core, $rule ) = get_core_type_and_rule($core);

    my $time_since_successful_extension
      = RulesAskedSoFar::TimeSinceRuleUsedToExtendSuccessfully($rule);
    my $time_since_unsuccessful_extension
      = RulesAskedSoFar::TimeSinceRuleUsedToExtendUnsuccessfully($rule);

    if ($time_since_successful_extension) {
       SCodelet->new('MaybeAskUsingThisGoodRule', 100, 
                     {   core      => $core,
                       rule      => $rule,
                       exception => $exception, })->schedule();
    }
    else {
      my $success;
      if ( $type_of_core eq 'relation' ) {
        SLTM::SpikeBy( 10, $core->get_type() );
        
        my $strength = $core->get_strength;

        # main::message("Strength for asking: $strength", 1);
        return unless SUtil::toss( $strength / 100 );
      }
      else {
        SCodelet->new('DoTheAsking', 100, 
                      {  core      => $core,
                        exception => $exception, })->schedule();
      }
      if ($success) {
        RulesAskedSoFar::AddRuleToSuccessList($rule);
      }
      else {
        RulesAskedSoFar::AddRuleToFailureList($rule);
      }
    }
  }
);

sub get_core_type_and_rule {
  my ($core) = @_;
  my $type_of_core =
    UNIVERSAL::isa( $core, 'SRelation' ) ? 'relation'
    : UNIVERSAL::isa( $core, 'SRuleApp' ) ? 'ruleapp'
    :                                       confess "Strange core $core";
    my $rule = ( $type_of_core eq 'relation' ) ? createRule($core) : $core->get_rule();
    return ( $type_of_core, $rule );
}

__PACKAGE__->meta->make_immutable;

1;

package SCF::MaybeAskUsingThisGoodRule;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;

Codelet_Family(
  attributes => [core => {}, rule => {}, exception => {}],
  body => sub {
    my ($core, $rule, $exception) = @_;
    SCodelet->new('DoTheAsking', 100, 
                  {    core       => $core,
                    exception  => $exception,
                    msg_prefix => "I know I have asked this before...",})->schedule();
  }
);

__PACKAGE__->meta->make_immutable;

package SCF::DoTheAsking;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;
multimethod 'createRule';

Codelet_Family(
  attributes => [core => {}, exception => {}, msg_prefix => {defualt => ""}],
  body => sub {
    my ($core, $exception, $msg_prefix) = @_;
    main::message("DoTheAsking called");

    my ( $type_of_core, $rule ) = SCF::MaybeAskTheseTerms::get_core_type_and_rule($core);
    my $success;
    if ( $type_of_core eq 'relation' ) {
      $success = $exception->AskBasedOnRelation( $core, $msg_prefix );
    }
    else {
      $success = $exception->AskBasedOnRuleApp( $core, $msg_prefix );
    }

    if ($success) {
      RulesAskedSoFar::AddRuleToSuccessList($rule);
    }
    else {
      RulesAskedSoFar::AddRuleToFailureList($rule);
    }

  }
);

__PACKAGE__->meta->make_immutable;


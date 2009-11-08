{

package SCF::MaybeAskTheseTerms;
our $package_name_ = 'SCF::MaybeAskTheseTerms';
our $NAME = 'SCF::MaybeAskTheseTerms';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 use Class::Multimethods qw{createRule}; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $core = $opts_ref->{core} // confess "Needed 'core', only got " . join(';', keys %$opts_ref);
	my $exception = $opts_ref->{exception} // confess "Needed 'exception', only got " . join(';', keys %$opts_ref);

    my ( $type_of_core, $rule ) = get_core_type_and_rule($core);

        my $time_since_successful_extension
            = RulesAskedSoFar::TimeSinceRuleUsedToExtendSuccessfully($rule);
        my $time_since_unsuccessful_extension
            = RulesAskedSoFar::TimeSinceRuleUsedToExtendUnsuccessfully($rule);

        if ($time_since_successful_extension) {
            SCodelet->new("MaybeAskUsingThisGoodRule", 
                         100,
                         {
                core      => $core,
                rule      => $rule,
                exception => $exception,
                })->schedule(); 
;
        }
        elsif ($time_since_unsuccessful_extension) {
            SCodelet->new("MaybeAskUsingThisUnlikelyRule", 
                         50,
                         {
                core      => $core,
                rule      => $rule,
                exception => $exception,
                })->schedule(); 
;
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
                SCodelet->new("DoTheAsking", 
                         100,
                         {
                    core      => $core,
                    exception => $exception,
                    })->schedule(); 
;

            }
            if ($success) {
                RulesAskedSoFar::AddRuleToSuccessList($rule);
            }
            else {
                RulesAskedSoFar::AddRuleToFailureList($rule);
            }
        }
    
}
 # end run


        sub get_core_type_and_rule {
            my ($core) = @_;
            my $type_of_core =
                  UNIVERSAL::isa( $core, 'SRelation' ) ? 'relation'
                : UNIVERSAL::isa( $core, 'SRuleApp' ) ? 'ruleapp'
                :                                       confess "Strange core $core";
            my $rule = ( $type_of_core eq 'relation' ) ? createRule($core) : $core->get_rule();
            return ( $type_of_core, $rule );
        }

    

1;
} # end surrounding

;


{

package SCF::DoTheAsking;
our $package_name_ = 'SCF::DoTheAsking';
our $NAME = 'SCF::DoTheAsking';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 use Class::Multimethods qw{createRule}; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $core = $opts_ref->{core} // confess "Needed 'core', only got " . join(';', keys %$opts_ref);
	my $exception = $opts_ref->{exception} // confess "Needed 'exception', only got " . join(';', keys %$opts_ref);
	my $msg_prefix = $opts_ref->{msg_prefix} // "";

    
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
 # end run


1;
} # end surrounding

;

{

package SCF::MaybeAskUsingThisGoodRule;
our $package_name_ = 'SCF::MaybeAskUsingThisGoodRule';
our $NAME = 'SCF::MaybeAskUsingThisGoodRule';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $core = $opts_ref->{core} // confess "Needed 'core', only got " . join(';', keys %$opts_ref);
	my $rule = $opts_ref->{rule} // confess "Needed 'rule', only got " . join(';', keys %$opts_ref);
	my $exception = $opts_ref->{exception} // confess "Needed 'exception', only got " . join(';', keys %$opts_ref);

    SCodelet->new("DoTheAsking", 
                         10000,
                         {
            core       => $core,
            exception  => $exception,
            msg_prefix => "I know I have asked this before...",
            })->schedule(); 
;
    
}
 # end run


1;
} # end surrounding




{

package SCF::MaybeAskUsingThisUnlikelyRule;
our $package_name_ = 'SCF::MaybeAskUsingThisUnlikelyRule';
our $NAME = 'SCF::MaybeAskUsingThisUnlikelyRule';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $core = $opts_ref->{core} // confess "Needed 'core', only got " . join(';', keys %$opts_ref);
	my $rule = $opts_ref->{rule} // confess "Needed 'rule', only got " . join(';', keys %$opts_ref);
	my $exception = $opts_ref->{exception} // confess "Needed 'exception', only got " . join(';', keys %$opts_ref);

    

    
}
 # end run


1;
} # end surrounding



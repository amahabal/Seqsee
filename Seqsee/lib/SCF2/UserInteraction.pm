
{

package SCF::AskIfThisIsTheContinuation;
our $package_name_ = 'SCF::AskIfThisIsTheContinuation';
our $NAME = 'Ask if This is the Intended Continuation';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 multimethod '__PlonkIntoPlace'; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $relation = $opts_ref->{relation} // 0;
	my $group = $opts_ref->{group} // 0;
	my $exception = $opts_ref->{exception} // confess "Needed 'exception', only got " . join(';', keys %$opts_ref);
	my $expected_object = $opts_ref->{expected_object} // confess "Needed 'expected_object', only got " . join(';', keys %$opts_ref);
	my $start_position = $opts_ref->{start_position} // confess "Needed 'start_position', only got " . join(';', keys %$opts_ref);
	my $known_term_count = $opts_ref->{known_term_count} // confess "Needed 'known_term_count', only got " . join(';', keys %$opts_ref);

    
        return unless $SWorkspace::ElementCount == $known_term_count;

        unless ($relation or $group) {
            confess "Need relation or ruleapp";
        }

        my $success;
        if ($relation) {
            $success = $exception->AskBasedOnRelation($relation, '');
        } else {
            $success = $exception->AskBasedOnGroup($group, '');
        }

        return unless $success;
        my $plonk_result = __PlonkIntoPlace( $start_position,
                                             $DIR::RIGHT,
                                             $expected_object );
        return unless ($plonk_result->PlonkWasSuccessful);

        if ($relation) {
            # We can establish the new relation!
            my $transform = $relation->get_type();
            my $new_relation = SRelation->new({first => $relation->get_second(),
                                               second => $plonk_result->get_resultant_object(),
                                               type => $transform,
                                           });
            $new_relation->insert();
        } else {
            # We can extend the group!
            my $ruleapp = $group->get_underlying_reln() or return;
            my $transform = $ruleapp->get_rule()->get_transform();
            my $new_object = $plonk_result->get_resultant_object();
            my $new_relation = SRelation->new({first => $group->[-1],
                                               second => $new_object, 
                                               type => $transform,
                                           });
            $new_relation->insert() or return;
            $group->Extend($new_object, 1);
        }
    
}
 # end run


1;
} # end surrounding



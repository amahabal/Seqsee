#####################################################
#
#    Package: SRule
#
#####################################################
#   Higher level structures than groups
#####################################################

package SRule;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};
use Smart::Comments;
use English qw(-no_match_vars);

our %StateCount_of : ATTR;                   # How many states?
our %TransitionFunction_of : ATTR;           # state->state
our %Relations_of : ATTR(:get<relations>);   # state->reln
our %FlippedRelations_of : ATTR;             # Fliped versions, if needed.
our %InverseTransitionFunction_of : ATTR;    # To move left. state->[state]
our %ReverseRelations_of : ATTR;             # To move left. state->reln.

our %Rejects_of :ATTR; # When has this rule been rejected?

multimethod 'apply_reln';

# Either provide SRelns in :relations and NOT provide flipped_relations, in which case the
# SRelnTypes of both relations and inverses are inferred.
# -- OR --
# Provide SRelnTypes for both relations and flipped_relations
sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $count       = $StateCount_of{$id}         = $opts_ref->{state_count};
    my $transitions = $TransitionFunction_of{$id} = $opts_ref->{transition_fn};
    my $relations   = $Relations_of{$id}          = $opts_ref->{relations};

    my $flipped_relations;
    if ( exists $opts_ref->{flipped_relations} ) {    # SRelnTypes provided for both.
        $flipped_relations = $FlippedRelations_of{$id} = $opts_ref->{flipped_relations};
    }
    else {    # So: only relations provided. Calculate SRelnTypes
        $flipped_relations = $FlippedRelations_of{$id}
            = [ map { FindTypeOfFlippedRelation($_) } @$relations ];
        $relations = $Relations_of{$id} = [ map { $_->get_type() } @$relations ];
    }

    my @inv_transition;
    for my $i ( 0 .. $count - 1 ) {
        push @{ $inv_transition[ $transitions->[$i] ] }, $i;
    }
    $InverseTransitionFunction_of{$id} = \@inv_transition;

    my @rev_reln;
    for my $i ( 0 .. $count - 1 ) {
        for my $prev_state ( @{ $inv_transition[$i] } ) {
            if ( $transitions->[$prev_state] == $i ) { # could also have been because of exceptions.
                push @{ $rev_reln[$i] }, $flipped_relations->[$prev_state];
            }
        }
    }
    $ReverseRelations_of{$id} = \@rev_reln;

}

sub FindTypeOfFlippedRelation{
    my ( $reln ) = @_;
    my $flipped_version = $reln->FlippedVersion();
    unless ($flipped_version) {
        ### Unable to flip relation!
        ### Relation: $reln->as_text()
        ### End 1: ($reln->get_ends())[0]->get_structure_string()
        ### End 2: ($reln->get_ends())[1]->get_structure_string()
        confess "Unable to flip relation!";
    }
    return $flipped_version->get_type();
}


{
    my %MEMO = ();
    multimethod createRule => qw(SReln) => sub {
        my ($reln) = @_;

        return $MEMO{ $reln->get_type() } ||= SRule->new(
            {   state_count   => 1,
                transition_fn => [0],
                relations     => [$reln],
            }
        );
    };
}

{
    my %MEMO = ();
    multimethod createRule => qw(SReln SReln) => sub {
        my ( $reln1, $reln2 ) = @_;

        my $key = join( ';', $reln1->get_type(), $reln2->get_type() );
        return $MEMO{$key} ||= SRule->new(
            {   state_count   => 2,
                transition_fn => [ 1, 0 ],
                relations     => [ $reln1, $reln2 ],
            }
        );
    };
}

sub create{
    my ( $package ) = shift;
    createRule(@_);
}


# method CreateApplication( $self: SObject +$start, Int +$state ) returns SRuleApp
sub CreateApplication {
    my ( $self, $opts_ref ) = @_;
    my $start     = $opts_ref->{start}     or confess;
    my $direction = $opts_ref->{direction} or confess;
    my $state     = $opts_ref->{state};
    confess unless defined $state;

    return SRuleApp->new(
        {
            rule      => $self,
            items     => [$start],
            states    => [$state],
            direction => $direction
        }
    );
}

# method GetRelationAndTransition( $self: Int $state ) returns (SReln, Int)
sub GetRelationAndTransition {
    my ( $self, $state ) = @_;
    my $id = ident $self;
    return ( $Relations_of{$id}->[$state], $TransitionFunction_of{$id}->[$state] );
}

# method GetRelationAndTransition( $self: Int $state ) returns (SReln, Int)
sub GetReverseRelationAndTransition {
    my ( $self, $state ) = @_;
    my $id = ident $self;

    my $prev_state_ref = $InverseTransitionFunction_of{$id}->[$state];
    my $prev_state;
    if ( scalar(@$prev_state_ref) == 1 ) {
        $prev_state = $prev_state_ref->[0];
    }
    else {
        confess "problematic reversals not implemented";
    }

    my $rev_reln_ref = $ReverseRelations_of{$id}->[$state];
    my $rev_reln;
    if ( scalar(@$rev_reln_ref) == 1 ) {
        $rev_reln = $rev_reln_ref->[0];
        ## rev_reln: $rev_reln
    }
    else {
        confess "problematic reversals not implemented";
    }

    return ( $rev_reln, $prev_state );
}

sub CheckApplicability{
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    my $objects_ref = $opts_ref->{objects} or confess;
    my $direction = $opts_ref->{direction} or confess;
    my $from_state  = $opts_ref->{from_state};   # If undefined, try all states.
    my $state_count = $StateCount_of{$id};

    my @states_to_check_from =
      ( defined $from_state ) ? ($from_state) : ( 0 .. $state_count - 1 );

    LOOP: for my $start_state (@states_to_check_from) {
        my @objects_to_account_for = @$objects_ref;
        my @accounted_for = shift(@objects_to_account_for);
        my @states = ($start_state);

        my ($last_object, $last_state) = ($accounted_for[0]->GetEffectiveObject(), $states[0]);
        while (@objects_to_account_for) {
            my ($reln, $next_state) = 
                $self->GetRelationAndTransition($last_state);
            my $expected_next = apply_reln($reln, $last_object) or confess('Apply relation failed');
            my $actual_next = shift(@objects_to_account_for);
            if ($expected_next->get_structure_string() eq
                    $actual_next->GetEffectiveObject()->get_structure_string())
                {
                    push @accounted_for, $actual_next;
                    push @states, $next_state;
                    ($last_object, $last_state) = ($actual_next->GetEffectiveObject(), $next_state);
                } else {
                    next LOOP;
                }
        }
        return SRuleApp->new({
            rule => $self,
            items => \@accounted_for,
            states => \@states,
            direction => $direction,
                });
    }

    return;
}


sub AttemptApplication {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    my $start     = $opts_ref->{start}     or confess;
    my $terms     = $opts_ref->{terms}     or confess;
    my $direction = $opts_ref->{direction} or confess;
    my $from_state  = $opts_ref->{from_state};   # If undefined, try all states.
    my $state_count = $StateCount_of{$id};

    my @states_to_check_from =
      ( defined $from_state ) ? ($from_state) : ( 0 .. $state_count - 1 );

    for my $start_state (@states_to_check_from) {
        ## Checking state: $start_state
        my $ruleapp =
          $self->CreateApplication(
            { start => $start, state => $start_state, direction => $direction }
          );
        return $ruleapp if ( $terms == 1 );
        ## ruleapp: $ruleapp
        my $extension_works = eval { $ruleapp->ExtendForward( $terms - 1 ) };
        if ( my $e = $EVAL_ERROR ) {
            $e->throw() unless UNIVERSAL::isa( $e, 'SErr::ConflictingGroups' );

            # XXX(Board-it-up): [2006/11/17] I should use this info!
            $extension_works = 0;
        }
        if ($extension_works) {
            return $ruleapp;
        }
    }

    return;                                       # Failed!
}

sub has_been_rejected {
    my ($self)       = @_;
    my $id           = ident $self;
    my @reject_times = @{ $Rejects_of{$id} ||= [] };
    return unless @reject_times;
    return 1 + ( $Global::Steps_Finished - $reject_times[0] );
}

sub suitability{
    my ( $self ) = @_;
    my $id = ident $self;
    my @reject_times = @{ $Rejects_of{$id} ||= [] };
    my $epoch = $Global::Steps_Finished;
    return 1 - List::Util::sum(map { 20 / (1 + $epoch - $_) } @reject_times);
}


sub Reject {
    my ($self) = @_;
    unshift @{ $Rejects_of{ ident $self} }, $Global::Steps_Finished;
}

sub as_text{
    my ( $self ) = @_;
    return "Rule: {" . join('}; {', map { $_->as_text() } @{$Relations_of{ident $self}}) . '}'
}


1;

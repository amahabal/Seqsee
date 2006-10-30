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

our %StateCount_of : ATTR;                   # How many states?
our %TransitionFunction_of : ATTR;           # state->state
our %Relations_of : ATTR;                    # state->reln
our %InverseTransitionFunction_of : ATTR;    # To move left. state->[state]
our %ReverseRelations_of : ATTR;             # To move left. state->reln.

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $count       = $StateCount_of{$id}         = $opts_ref->{state_count};
    my $transitions = $TransitionFunction_of{$id} = $opts_ref->{transition_fn};
    my $relations   = $Relations_of{$id}          = $opts_ref->{relations};

    my @inv_transition;
    for my $i ( 0 .. $count - 1 ) {
        push @{ $inv_transition[ $transitions->[$i] ] }, $i;
    }
    $InverseTransitionFunction_of{$id} = \@inv_transition;

    my @rev_reln;
    for my $i ( 0 .. $count - 1 ) {
        for my $prev_state ( @{ $inv_transition[$i] } ) {
            if ( $transitions->[$prev_state] == $i ) { # could also have been because of exceptions.
                push @{ $rev_reln[$i] }, $relations->[$prev_state]->FlippedVersion;
            }
        }
    }
    $ReverseRelations_of{$id} = \@rev_reln;
}

{
    my %MEMO = ();
    multimethod createRule => qw(SReln) => sub {
        my ($reln) = @_;

        # XXX(Board-it-up): [2006/10/29] I need relation type; I aready have such code along
        # the ltm branch; Use it after merge.
        return $MEMO{$reln} ||= SRule->new(
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

        # XXX(Board-it-up): [2006/10/29] I need relation type; I aready have such code along
        # the ltm branch; Use it after merge.
        my $key = "$reln1;$reln2";
        return $MEMO{$key} ||= SRule->new(
            {   state_count   => 2,
                transition_fn => [ 1, 0 ],
                relations     => [ $reln1, $reln2 ],
            }
        );
    };
}

# method CreateApplication( $self: SObject +$start, Int +$state ) returns SRuleApp
sub CreateApplication {
    my ( $self, $opts_ref ) = @_;
    my $start = $opts_ref->{start} or confess;
    my $state = $opts_ref->{state};
    confess unless defined $state;

    return SRuleApp->new( { rule => $self, items => [$start], states => [$state] } );
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

sub AttemptApplication {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    my $start = $opts_ref->{start} or confess;
    my $terms = $opts_ref->{terms} or confess;
    my $from_state  = $opts_ref->{from_state};    # If undefined, try all states.
    my $state_count = $StateCount_of{$id};

    my @states_to_check_from = ( defined $from_state ) ? ($from_state) : ( 0 .. $state_count - 1 );

    for my $start_state (@states_to_check_from) {
        my $ruleapp = $self->CreateApplication( { start => $start, state => $start_state } );
        if ( $ruleapp->ExtendRight( $terms - 1 ) ) {
            return $ruleapp;
        }
    }

    return;                                       # Failed!
}

1;

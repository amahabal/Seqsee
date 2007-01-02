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
our %Relations_of : ATTR;                    # state->reln
our %FlippedRelations_of : ATTR;             # Fliped versions, if needed.
our %InverseTransitionFunction_of : ATTR;    # To move left. state->[state]
our %ReverseRelations_of : ATTR;             # To move left. state->reln.

our %Rejects_of :ATTR; # When has this rule been rejected?

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
            = [ map { $_->FlippedVersion()->get_type() } @$relations ];
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
        ## Checking state: $start_state
        my $ruleapp = $self->CreateApplication( { start => $start, state => $start_state } );
        return $ruleapp if ($terms == 1);
        ## ruleapp: $ruleapp
        my $extension_works = eval { $ruleapp->ExtendRight( $terms - 1) };
        if (my $e = $EVAL_ERROR) {
            $e->throw() unless UNIVERSAL::isa($e, 'SErr::ConflictingGroups');
            # XXX(Board-it-up): [2006/11/17] I should use this info!
            $extension_works = 0;
        }
        if ( $extension_works ) {
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

sub Reject {
    my ($self) = @_;
    unshift @{ $Rejects_of{ ident $self} }, $Global::Steps_Finished;
}

sub as_text{
    my ( $self ) = @_;
    return "Rule: {" . join('}; {', map { $_->as_text() } @{$Relations_of{ident $self}}) . '}'
}


1;

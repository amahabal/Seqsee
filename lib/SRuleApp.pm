#####################################################
#
#    Package: SRuleApp
#
#####################################################
#   Application of a rule: the structure created by applying a rule to part of a sequence
#####################################################

package SRuleApp;
use strict;
use Carp;
use Class::Std;
use English qw{-no-match-vars};
use base qw{};
use Smart::Comments;

use Class::Multimethods;
for (qw{apply_reln plonk_into_place find_reln}) {
    multimethod $_;
}

my %Rule_of : ATTR;      # The underlying rule.
my %Items_of : ATTR(:get<items>);     # Objects to which the rule has been applied.
my %States_of : ATTR;    # The states corresponding to the types.

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $Rule_of{$id}   = $opts_ref->{rule}   or confess;
    $Items_of{$id}  = $opts_ref->{items}  or confess;
    $States_of{$id} = $opts_ref->{states} or confess;
}

# method GetItems( $self:  ) returns [@SObjects]
sub GetItems {
    my ($self) = @_;
    return $Items_of{ ident $self};
}

sub GetStates {
    my ($self) = @_;
    return $States_of{ ident $self};
}

sub ExtendInDirection {
    my ( $self, $id, $direction, $object_at_end, $relation, $next_state ) = @_;
    my $next_pos = $object_at_end->get_next_pos_in_dir($direction);
    ## next_pos: $next_pos
    return unless defined $next_pos;
    my $next_object = apply_reln( $relation, $object_at_end->get_effective_object() );
    ## next_object: $next_object, $next_object->get_structure_string()

    my $is_this_what_is_present = eval { SWorkspace->check_at_location(
        {   start     => $next_pos,
            direction => $direction,
            what      => $next_object
        }
    )};
    if (my $e = $EVAL_ERROR) {
        die $e unless UNIVERSAL::isa($e, 'SErr::AskUser');
        # XXX(Board-it-up): [2007/01/01] Trust level clearly should not be 1..
        if ($e->WorthAsking(1)) {
            $is_this_what_is_present = $e->Ask('(while extending rule)');
        }
    }
    ## is_this_what_is_present: $is_this_what_is_present

    if ($is_this_what_is_present) {
        my $wso = plonk_into_place( $next_pos, $direction, $next_object );
        if ( $direction eq $DIR::RIGHT ) {
            push @{ $Items_of{$id} },  $wso;
            push @{ $States_of{$id} }, $next_state;
        }
        elsif ( $direction eq $DIR::LEFT ) {
            unshift @{ $Items_of{$id} },  $wso;
            unshift @{ $States_of{$id} }, $next_state;
        }
        else {
            confess "Huh?";
        }

        my $relation = find_reln($object_at_end, $next_object);
        $relation->insert();
        return 1;
    }
    else {
        return 0;
    }
}

# method ExtendRight( $self:  )
sub ExtendRight {
    my ( $self, $steps ) = @_;
    $steps ||= 1;
    my $id = ident $self;

    my $items_ref  = $Items_of{$id};
    my $states_ref = $States_of{$id};
    my $count      = scalar(@$states_ref);    # Useful for undo
    my $rule       = $Rule_of{$id};

    for ( 1 .. $steps ) {
        ## Extending step: $_
        my $current_rightmost = $items_ref->[-1];
        my $rightmost_state   = $states_ref->[-1];
        my ( $relation, $next_state ) = $rule->GetRelationAndTransition($rightmost_state);
        ## relation, next_state: ident $relation, $next_state
        my $result = $self->ExtendInDirection( $id, $DIR::RIGHT, $current_rightmost, $relation,
            $next_state );
        ## result of extending: $result
        unless ($result) {                    # Could not extend as many steps as desired!
            splice( @$items_ref,  $count );
            splice( @$states_ref, $count );
            return;
        }
    }
    return 1;
}

sub ExtendLeft {
    my ( $self, $steps ) = @_;
    $steps ||= 1;
    my $id = ident $self;

    my $items_ref  = $Items_of{$id};
    my $states_ref = $States_of{$id};
    my $count      = scalar(@$states_ref);    # Useful for undo
    my $rule       = $Rule_of{$id};

    for my $step ( 1 .. $steps ) {
        my $current_leftmost = $items_ref->[0];
        my $leftmost_state   = $states_ref->[0];
        my ( $relation, $next_state ) = $rule->GetReverseRelationAndTransition($leftmost_state);
        my $result = $self->ExtendInDirection( $id, $DIR::LEFT, $current_leftmost, $relation,
            $next_state );
        unless ($result) {                    # Could not extend as many steps as desired!
            splice( @$items_ref,  0, $step - 1 );
            splice( @$states_ref, 0, $step - 1 );
            return;
        }
    }
    return 1;
}

1;

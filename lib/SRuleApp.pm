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
for (qw{apply_reln __PlonkIntoPlace find_reln}) {
    multimethod $_;
}

my %Rule_of : ATTR(:get<rule>);    # The underlying rule.
my %Items_of : ATTR(:get<items>);  # Objects to which the rule has been applied.
my %States_of : ATTR;              # The states corresponding to the types.
my %Direction_of : ATTR;           # Direction of application (Right/Left).

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $Rule_of{$id}      = $opts_ref->{rule}      or confess;
    $Items_of{$id}     = $opts_ref->{items}     or confess;
    $States_of{$id}    = $opts_ref->{states}    or confess;
    $Direction_of{$id} = $opts_ref->{direction} or confess;
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

sub CheckConsitencyOfGroup {
    my ( $self, $group ) = @_;
    my $id = ident $self;

    # If the ruleapp does not fully cover group, it in not inconsistent
    my ( $left,    $right )    = $self->get_edges();
    my ( $gp_left, $gp_right ) = $group->get_edges();
    return 1 unless ($gp_left >= $left and $gp_right <= $right);
    return 1 if $group->get_underlying_reln() eq $self;

    # Reasons for consistency:
    # a: is an item.
    # b: is an item of the item etc.
    for my $item ( @{ $Items_of{$id} } ) {
        return 1 if $group eq $item;    #Reason a
        return 1 if $item->HasAsPartDeep($group);    # Reason b
    }

    return 0;
}

sub CheckConsitencyOfRelation{
    my ( $self, $reln ) = @_;
    return 1;
    my $id = ident $self;
    my @items = @{$Items_of{$id}};

    # If the ruleapp does not fully cover either end, it in not inconsistent   
    my ( $left,    $right )    = $self->get_edges();
    my ($end1, $end2) = $reln->get_ends();
    my ($e1left, $e1right, $e2left, $e2right) = map { $_->get_edges() } ($end1, $end2);
    my $some_end_overlaps = 0;

    # Check if end1 overlaps:
    if ($e1left >= $left and $e1right <= $right) {
        
    }
    


}


sub ExtendInDirection {
    my (
        $self, $id,
        $direction,        # Direction to extend in (Right/Left)
        $object_at_end,    # First/Last object, depending on direction
        $relation,         # Relation to use for extension
        $next_state,       # Resulting state
        $start_or_end      # a string 'start' or 'end': where to add.
    ) = @_;

    my $next_pos = $object_at_end->get_next_pos_in_dir($direction);
    ## next_pos: $next_pos
    return unless defined $next_pos;
    my $next_object =
      apply_reln( $relation, $object_at_end->GetEffectiveObject() );
    ## next_object: $next_object, $next_object->get_structure_string()

    my $is_this_what_is_present = eval {
        SWorkspace->check_at_location(
            {
                start     => $next_pos,
                direction => $direction,
                what      => $next_object
            }
        );
    };
    if ( my $e = $EVAL_ERROR ) {
        die $e unless UNIVERSAL::isa( $e, 'SErr::AskUser' );

        my $trust_level = ($self->get_span() / $SWorkspace::elements_count) * 0.5;
        ### span: $self->get_span()
        ### count: $SWorkspace::elements_count
        ### trust: $trust_level
        # log(scalar(@{$self->get_items})) / log(3);
        if ( $e->WorthAsking($trust_level) ) {
            $is_this_what_is_present = $e->Ask('(while extending rule)');
        }
    }
    ## is_this_what_is_present: $is_this_what_is_present

    if ($is_this_what_is_present) {
        my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $next_object);
        confess "__PlonkIntoPlace failed. Shouldn't have, I think" 
            unless $plonk_result->PlonkWasSuccessful();
        my $wso = $plonk_result->get_resultant_object();
        my $reln;
        if ( $start_or_end eq 'end' ) {
            push @{ $Items_of{$id} },  $wso;
            push @{ $States_of{$id} }, $next_state;
            $reln = find_reln( $object_at_end, $wso );
        }
        elsif ( $start_or_end eq 'start' ) {
            unshift @{ $Items_of{$id} },  $wso;
            unshift @{ $States_of{$id} }, $next_state;
            $reln = find_reln( $wso, $object_at_end );
        }
        else {
            confess "Huh?";
        }

        unless ($reln) {
            my @wso_cats = map { $_->get_name() } @{ $wso->get_categories() };
            my @object_at_end_cats =
              map { $_->get_name() } @{ $object_at_end->get_categories() };
            my @wso_part_cats = map {
                [ map { $_->get_name() } @{ $_->get_categories() } ]
            } @$wso;
            my @object_part_cats = map {
                [ map { $_->get_name() } @{ $_->get_categories() } ]
            } @$object_at_end;
            ### No reln Found: $wso, $object_at_end
            ### wso structure: $wso->get_structure_string()
            ### (but effectively) : $wso->GetEffectiveStructureString()
            ### (categories) : @wso_cats
            ### (part categories): @wso_part_cats
            ### object_at_end structure: $object_at_end->get_structure_string()
            ### (but effectively) : $object_at_end->GetEffectiveStructureString()
            ### (categories) : @object_at_end_cats
            ### (part categories): @object_part_cats

            # XXX(Board-it-up): [2007/02/20] Should die. But there is a bug
            # currently that needs to be fixed. Relation between [1 2 3] and
            # [1 [2 2] 3] not being seen.
            #confess "Relation should have been found!";
            return;
        }
        $reln->insert();
        return 1;
    }
    else {
        return 0;
    }
}

sub FindExtension {
    my ( $self, $direction_to_extend_in, $opts_ref ) = @_;
    my $id                = ident $self;
    my $items_ref         = $Items_of{$id};
    my $states_ref        = $States_of{$id};
    my $skip              = $opts_ref->{skip} || 0;
    my $count             = scalar(@$states_ref);     # Useful for undo
    my $rule              = $Rule_of{$id};
    my $direction_of_self = $Direction_of{$id};

    ## current runnable: $Global::CurrentRunnableString
    ## self, to_extend_in: $direction_of_self, $direction_to_extend_in
    ## skip: $skip

    my ( $last_object, $relation, $next_state );
    if ( $direction_of_self eq $direction_to_extend_in ) {
        $last_object = $items_ref->[ -1 - $skip ];
        my $last_state = $states_ref->[ -1 - $skip ];
        ( $relation, $next_state ) =
          $rule->GetRelationAndTransition($last_state);
    }
    else {
        $last_object = $items_ref->[$skip];
        ## skip: $skip
        ## items_ref: $items_ref
        ## last_object: $last_object->as_text()
        my $last_state = $states_ref->[$skip];
        ( $relation, $next_state ) =
          $rule->GetReverseRelationAndTransition($last_state);
    }

    my $next_pos = $last_object->get_next_pos_in_dir($direction_to_extend_in);
    return unless defined $next_pos;
    ## next_pos: $next_pos

    my $expected_next_object =
      apply_reln( $relation, $last_object->GetEffectiveObject() )
      or return;

    return SWorkspace->GetSomethingLike(
        {
            object      => $expected_next_object,
            start       => $next_pos,
            direction   => $direction_to_extend_in,
            trust_level => 50 *
              $self->get_span() /
              ( $SWorkspace::elements_count + 1 ),    # !!
            reason => 'Extension attempted for: ' . $rule->as_text(),
        }
    );
}

sub ExtendForward {
    my ( $self, $steps ) = @_;
    $steps ||= 1;
    my $id = ident $self;

    my $direction_to_extend_in = $Direction_of{$id};

    my $items_ref  = $Items_of{$id};
    my $states_ref = $States_of{$id};
    my $count      = scalar(@$states_ref);    # Useful for undo
    my $rule       = $Rule_of{$id};

    for ( 1 .. $steps ) {
        ## Extending step: $_
        my $current_rightmost = $items_ref->[-1];
        my $rightmost_state   = $states_ref->[-1];
        my ( $relation, $next_state ) =
          $rule->GetRelationAndTransition($rightmost_state);
        ## relation, next_state: ident $relation, $next_state
        my $result =
          $self->ExtendInDirection( $id, $direction_to_extend_in,
            $current_rightmost, $relation, $next_state, 'end', );
        ## result of extending: $result
        unless ($result) {    # Could not extend as many steps as desired!
            splice( @$items_ref,  $count );
            splice( @$states_ref, $count );
            return;
        }
    }
    Global::UpdateGroupStrengthByConsistency();
    return 1;
}

sub ExtendBackward {
    my ( $self, $steps ) = @_;
    $steps ||= 1;
    my $id = ident $self;

    my $direction_to_extend_in = $Direction_of{$id}->Flip();

    my $items_ref  = $Items_of{$id};
    my $states_ref = $States_of{$id};
    my $count      = scalar(@$states_ref);    # Useful for undo
    my $rule       = $Rule_of{$id};

    for my $step ( 1 .. $steps ) {
        my $current_leftmost = $items_ref->[0];
        my $leftmost_state   = $states_ref->[0];
        my ( $relation, $next_state ) =
          $rule->GetReverseRelationAndTransition($leftmost_state);
        my $result =
          $self->ExtendInDirection( $id, $direction_to_extend_in,
            $current_leftmost, $relation, $next_state, 'start' );
        unless ($result) {    # Could not extend as many steps as desired!
            splice( @$items_ref,  0, $step - 1 );
            splice( @$states_ref, 0, $step - 1 );
            return;
        }
    }
    Global::UpdateGroupStrengthByConsistency();
    return 1;
}

sub ExtendRight {
    my ( $self, $steps ) = @_;
    my $direction = $Direction_of{ ident $self};
    if ( $direction eq $DIR::RIGHT ) {
        $self->ExtendForward($steps);
    }
    elsif ( $direction eq $DIR::LEFT ) {
        $self->ExtendBackward($steps);
    }
    else {
        confess "Huh?";
    }
}

sub ExtendLeft {
    my ( $self, $steps ) = @_;
    my $direction = $Direction_of{ ident $self};
    if ( $direction eq $DIR::LEFT ) {
        $self->ExtendForward($steps);
    }
    elsif ( $direction eq $DIR::RIGHT ) {
        $self->ExtendBackward($steps);
    }
    else {
        confess "Huh?";
    }
}

sub ExtendLeftMaximally {
    my ($self) = @_;
    my $id = ident $self;

    my $items_ref  = $Items_of{$id};
    my $states_ref = $States_of{$id};
    my $count      = scalar(@$states_ref);    # Useful for undo
    my $rule       = $Rule_of{$id};

    my $current_leftmost  = $items_ref->[0];
    my $leftmost_state    = $states_ref->[0];
    my $current_left_edge = $current_leftmost->get_left_edge();

    while ( $current_left_edge > 0 ) {
        my ( $relation, $next_state ) =
          $rule->GetReverseRelationAndTransition($leftmost_state);
        my $direction_of_self = $Direction_of{$id};
        my $start_or_end =
          ( $direction_of_self eq $DIR::RIGHT ) ? 'start' : 'end';
        my $result =
          $self->ExtendInDirection( $id, $DIR::LEFT, $current_leftmost,
            $relation, $next_state, $start_or_end );

        if ($result) {
            $current_leftmost  = $items_ref->[0];
            $leftmost_state    = $states_ref->[0];
            $current_left_edge = $current_leftmost->get_left_edge();
        }
        else {
            return;
        }
    }
}

sub as_text {
    my ($self) = @_;
    return "SRuleApp $self";
}

sub suggest_cat {
    my ($self) = @_;
    my $relations_ref = $Rule_of{ ident $self}->get_relations();
    if ( scalar(@$relations_ref) == 1 ) {
        return $relations_ref->[0]->suggest_cat();
    }
    else {
        return;
    }
}

sub suggest_cat_for_ends {
    my ($self) = @_;
    my $relations_ref = $Rule_of{ ident $self}->get_relations();
    if ( scalar(@$relations_ref) == 1 ) {
        return $relations_ref->[0]->suggest_cat_for_ends();
    }
    else {
        return;
    }
}

sub get_span {
    my ($self) = @_;
    return List::Util::sum( map { $_->get_span() }
          @{ $Items_of{ ident $self} } );
}

sub get_edges{
    my ( $self ) = @_;
    my $id = ident $self;
    my @items = @{$Items_of{$id}};

    return List::MoreUtils::minmax(map { $_->get_edges() } @items);
    
}


1;

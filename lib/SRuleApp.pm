package SRuleApp;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use English qw{-no-match-vars};
use base qw{};
use Smart::Comments;
use Class::Multimethods;

multimethod 'ApplyTransform';
multimethod 'FindTransform';

my %Rule_of : ATTR(:name<rule>);              # The underlying rule.
my %Items_of : ATTR(:name<items>);            # Objects to which the rule has been applied.
my %Direction_of : ATTR(:name<direction>);    # Direction of application (Right/Left).

sub CheckConsitencyOfGroup {                  #CHECK THIS CODE
    my ( $self, $group ) = @_;
    my $id = ident $self;

    # If the ruleapp does not fully cover group, it is still consistent
    my ( $left,    $right )    = $self->get_edges();
    my ( $gp_left, $gp_right ) = $group->get_edges();
    return 1 unless ( $gp_left >= $left and $gp_right <= $right );
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

sub CheckConsitencyOfRelation {                      #CHECK THIS CODE
    my ( $self, $reln ) = @_;
    return 1;
    my $id    = ident $self;
    my @items = @{ $Items_of{$id} };

    # If the ruleapp does not fully cover either end, it in not inconsistent
    my ( $left, $right ) = $self->get_edges();
    my ( $end1, $end2 )  = $reln->get_ends();
    my ( $e1left, $e1right, $e2left, $e2right ) = map { $_->get_edges() } ( $end1, $end2 );
    my $some_end_overlaps = 0;

    # Check if end1 overlaps:
    if ( $e1left >= $left and $e1right <= $right ) {

    }
}

sub FindExtension {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    my $rule      = $Rule_of{$id};
    my $items_ref = $Items_of{$id};

    my $direction_to_extend_in = $opts_ref->{direction_to_extend_in}
        or confess "need direction_to_extend_in";
    my $skip_this_many_elements = $opts_ref->{skip_this_many_elements} || 0;
    my $direction_of_self = $Direction_of{$id};

    return if $skip_this_many_elements >= scalar(@$items_ref);
    my ( $last_object, $relation_to_use );
    if ( $direction_of_self eq $direction_to_extend_in ) {
        $last_object     = $items_ref->[ -1 - $skip_this_many_elements ];
        $relation_to_use = $rule->get_transform;
    }
    else {
        $last_object     = $items_ref->[$skip_this_many_elements];
        $relation_to_use = $rule->get_flipped_transform;
    }

    $relation_to_use // return;
    confess "Strange transform: $relation_to_use" unless UNIVERSAL::isa($relation_to_use, 'Transform'); 

    my $next_pos = $last_object->get_next_pos_in_dir($direction_to_extend_in) // return;
    my $expected_next_object
        = ApplyTransform( $relation_to_use, $last_object->GetEffectiveObject() ) or return;
    return unless @$expected_next_object;

    # XXX
    return SWorkspace->GetSomethingLike(    # This is crazy! Fix workflow.
        {   object      => $expected_next_object,
            start       => $next_pos,
            direction   => $direction_to_extend_in,
            trust_level => 50 * $self->get_span() / ( $SWorkspace::ElementCount + 1 ),    # !!
            reason    => '',              # 'Extension attempted for: ' . $rule->as_text(),
            hilit_set => [@$items_ref],
        }
    );

}

sub _ExtendOneStep {
    my ($opts_ref) = @_;

    my $items_ref = $opts_ref->{items_ref} or confess "need items_ref";
    my $direction_to_extend_in = $opts_ref->{direction_to_extend_in}
        or confess "need direction_to_extend_in";
    my $object_at_end = $opts_ref->{object_at_end} or confess "need object_at_end";
    my $transform     = $opts_ref->{transform}     or confess "need transform";
    my $extend_at_start_or_end = $opts_ref->{extend_at_start_or_end}
        or confess "need extend_at_start_or_end";

    my $next_pos = $object_at_end->get_next_pos_in_dir($direction_to_extend_in) // return;
    my $next_object = ApplyTransform( $transform, $object_at_end->GetEffectiveObject() );

    my $is_this_what_is_present = SWorkspace->check_at_location(
        {   start     => $next_pos,
            direction => $direction_to_extend_in,
            what      => $next_object
        }
    ) or return;

    my $plonk_result = __PlonkIntoPlace( $next_pos, $direction_to_extend_in, $next_object );
    confess "__PlonkIntoPlace failed. Shouldn't have, I think"
        unless $plonk_result->PlonkWasSuccessful();
    my $wso = $plonk_result->get_resultant_object();
    my $reln;
    given ($extend_at_start_or_end) {
        when ('end') {
            push @$items_ref, $wso;
            my $transform = FindTransform( $object_at_end, $wso ) or return;
            $reln
                = SRelation->new( { first => $object_at_end, second => $wso, type => $transform } );
        }
        when ('start') {
            unshift @$items_ref, $wso;
            my $transform = FindTransform( $wso, $object_at_end ) or return;
            $reln
                = SRelation->new( { first => $wso, second => $object_at_end, type => $transform } );
        }
        default {
            confess "Huh?";
        }
    }

    return unless $reln;
    $reln->insert();
    SLTM::SpikeBy( 200, $reln );
    return 1;
}

sub _ExtendSeveralSteps {
    my ( $self, $extend_at_start_or_end, $steps ) = @_;
    my $id = ident $self;
    $steps //= 1;

    my $index_of_end = ($extend_at_start_or_end eq 'end') ? -1 : 0;

    my $direction_to_extend_in = $Direction_of{$id};
    my @items                  = @{ $Items_of{$id} };
    my $count                  = scalar(@items);
    my $rule                   = $Rule_of{$id};
    my $transform              = $rule->get_transform();

    for ( 1 .. $steps ) {
        my $current_end = $items[$index_of_end];
        my $success;
        
       eval { 
            $success = _ExtendOneStep(
                {   items_ref              => \@items,
                    direction_to_extend_in => $direction_to_extend_in,
                    object_at_end          => $current_end,
                    transform              => $transform,
                    extend_at_start_or_end => $extend_at_start_or_end,
                }
            );
         };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::ElementsBeyondKnownSought')) { 
                my $trust_level
                    = 0.5 
                    * List::Util::sum( map { $_->get_span() } @items )
                    / $SWorkspace::ElementCount;
                return unless SUtil::toss($trust_level);
                SCoderack->add_codelet(
                    SCodelet->new(
                        'MaybeAskTheseTerms',
                        10000,
                        {   core      => $self,
                            exception => $err,
                        }
                    )
                );
                return;
            ; last CATCH_BLOCK; }die $err }
       }
    

        return unless $success;
    }
    $Items_of{$id} = \@items;
    Global::UpdateGroupStrengthByConsistency();
    return 1;
}

sub ExtendForward {
    my ( $self, $steps ) = @_;
    $self->_ExtendSeveralSteps('end', $steps);
}
sub ExtendBackward {
    my ( $self, $steps ) = @_;
    $self->_ExtendSeveralSteps('start', $steps);
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

    while ( $self->ExtendLeft(1) ) {
    }
}

sub as_text {
    my ($self) = @_;
    return "SRuleApp $self";
}

sub get_span {
    my ($self) = @_;
    my ( $l, $r ) = $self->get_edges();
    return $r - $l + 1;
}

sub get_edges {
    my ($self) = @_;
    my $id     = ident $self;
    my @items  = @{ $Items_of{$id} };
    given ( $Direction_of{$id} ) {
        when ($DIR::RIGHT) {
            return ( $items[0]->get_left_edge(), $items[-1]->get_right_edge() );
        }
        when ($DIR::LEFT) {
            return ( $items[-1]->get_left_edge(), $items[0]->get_right_edge() );
        }
        default {
            confess "Huh?";
        }
    }
}

1;

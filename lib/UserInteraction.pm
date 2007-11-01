use Exception::Class ( 'SErr::ElementsBeyondKnownSought' => { fields => ['next_elements'], } );

package SErr::ElementsBeyondKnownSought;
use strict;
use Smart::Comments;
use Carp;

sub ActualQuestion {
    my ($self) = @_;
    my @items = @{ $self->next_elements() };
    ### require: @items

    if ( scalar(@items) == 1 ) {
        return "Is the next term $items[0]?";
    }
    else {
        my $count  = scalar(@items);
        my $return = "Are the next $count terms ";
        $return .= join( q{, }, @items[ 0 .. $count - 2 ] );
        $return .= q{,} if $count >= 3;
        $return .= qq{ and $items[-1]?};
        return $return;
    }
}

sub Ask {
    my ( $self, $question_prefix, $question_suffix, $debug_msg ) = @_;
    my @items = @{ $self->next_elements() };
    return if Seqsee::already_rejected_by_user( \@items );

    my $actual_question = $self->ActualQuestion();
    my $question = join( q{}, $question_prefix, $actual_question, $question_suffix );

    my $validated;
    if ( $Global::Feature{debug} ) {
        $validated = $SGUI::Commentary->MessageRequiringBooleanResponse( $question, '', $debug_msg,
            ['debug'] );
    }
    else {
        $validated = $SGUI::Commentary->MessageRequiringBooleanResponse($question);
    }
    if ($validated) {
        $self->DoInsertBookKeeping();
    }
    else {
        my $seq = join( ', ', @items );
        $Global::ExtensionRejectedByUser{$seq} = 1;
    }

    return $validated;
}

sub DoInsertBookKeeping {
    my ($self) = @_;
    my @items = @{ $self->next_elements() };
    SWorkspace->insert_elements(@items);
    $Global::AcceptableTrustLevel       = 0.5;
    $Global::AtLeastOneUserVerification = 1;
    main::update_display();

    $Global::Break_Loop = 1;
}

sub RuleAppPenetration {    # A number between 0 and 1
    my ( $self, $ruleapp_left_edge ) = @_;
    return 1 - ( $ruleapp_left_edge / $SWorkspace::ElementCount );
}

sub RelationPenetration {
    my ( $self, $relation ) = @_;

}

sub WorthAsking {
    confess "Should never be called. Caller does the dirty work.";
}

package RulesAskedSoFar;
our @SuccessfulRules;      # ([rule, time)] when user said yes to extension. Most recent first.
our @UnsuccessfulRules;    # ([rule, time)] when user said no to extension. Most recent first.

our %AcceptedRules;   # Key=val; Yes to the specific question: Does this rule describe the sequence?
our %RejectedRules;   # Key=val; No to the specific question: Does this rule describe the sequence?

# return -1 if never successful, or not last Q asked.
# Else return time since that question.
sub IsMostRecentSuccessfulRule {
    my ($rule) = @_;
    return -1 unless @SuccessfulRules;
    return -1 unless $SuccessfulRules[0][0] eq $rule;
    return $Global::Steps_Finished - $SuccessfulRules[0][1];
}

# Return 0 if never used to extend successfully.
sub TimeSinceRuleUsedToExtendSuccessfully {
    my ( $rule ) = @_;
    my $last_time_block = first { $_->[0] eq $rule } @SuccessfulRules;
    return 0 unless $last_time_block;
    return $Global::Steps_Finished - $last_time_block->[1];
}

# Return 0 if never used to extend unsuccessfully.
sub TimeSinceRuleUsedToExtendUnuccessfully {
    my ( $rule ) = @_;
    my $last_time_block = first { $_->[0] eq $rule } @UnsuccessfulRules;
    return 0 unless $last_time_block;
    return $Global::Steps_Finished - $last_time_block->[1];
}


sub AddRuleToSuccessList {
    my ($rule) = @_;
    unshift @SuccessfulRules, [ $rule, $Global::Steps_Finished ];
}

sub AddRuleToFailureList {
    my ($rule) = @_;
    unshift @UnsuccessfulRules, [ $rule, $Global::Steps_Finished ];
}

1;

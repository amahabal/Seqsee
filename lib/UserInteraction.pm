use Exception::Class ( 'SErr::ElementsBeyondKnownSought' => { fields => ['next_elements'], } );

package SErr::ElementsBeyondKnownSought;
use strict;
use Smart::Comments;
use Carp;

sub ActualQuestion {
    my ( $self ) = @_;
    my @items = @{$self->next_elements()};
    ### require: @items

    if (scalar(@items) == 1) {
        return "Is the next term $items[0]?";
    } else {
        my $count = scalar(@items);
        my $return = "Are the next $count terms ";
        $return .= join(q{, }, @items[0..$count-2]);
        $return .= q{,} if $count >= 3;
        $return .= qq{ and $items[-1]?};
        return $return;
    }
}

sub Ask {
    my ( $self, $question_prefix, $question_suffix, $debug_msg ) = @_;
    my @items = @{$self->next_elements()};
    return if Seqsee::already_rejected_by_user(\@items);

    my $actual_question = $self->ActualQuestion();
    my $question = join(q{}, $question_prefix, $actual_question, $question_suffix);

    my $validated;
    if ($Global::Feature{debug}) {
        $validated = $SGUI::Commentary->MessageRequiringBooleanResponse($question, '',
                                                                        $debug_msg, ['debug']
                                                                            );
    } else {
        $validated = $SGUI::Commentary->MessageRequiringBooleanResponse($question);
    }
    if ($validated) {
        $self->DoInsertBookKeeping();
    } else {
        my $seq = join(', ', @items);
        $Global::ExtensionRejectedByUser{$seq} = 1;
    }

    return $validated;
}

sub DoInsertBookKeeping {
    my ( $self ) = @_;
    my @items = @{$self->next_elements()};
    SWorkspace->insert_elements(@items);
    $Global::AcceptableTrustLevel = 0.5;
    $Global::AtLeastOneUserVerification = 1;
    main::update_display();

    $Global::Break_Loop = 1;
}

sub RuleAppPenetration { # A number between 0 and 1
    my ( $self, $ruleapp_left_edge ) = @_;
    return 1 - ($ruleapp_left_edge / $SWorkspace::ElementCount);
}

sub RelationPenetration {
    my ( $self, $relation ) = @_;
     
}


sub WorthAsking {
    confess "Should never be called. Caller does the dirty work.";
}

1;

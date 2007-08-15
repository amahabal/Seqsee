use strict;
use Config::Std;
use Smart::Comments;
use List::Util;
use Tk;
use Time::HiRes qw{time};

my @sequences_to_ask = ReadInputConfig("Inputlist.txt");
our $Position;
our %InfoToWriteOut;
### Sequences: @sequences_to_ask

my $MW = new MainWindow();
ShowSplashScreen();
MainLoop();

sub ReadInputConfig {
    my ($filename) = @_;
    read_config $filename => my %SequenceConfig;
    my @sequences;

    while ( my ( $set, $values ) = each %SequenceConfig ) {
        next if $set eq '';

        my $type = $values->{Type};
        my @sequences_in_set = @{ $values->{seq} } or die "No sequences for set $set!";

        if ( $type eq 'AskOne' ) {
            push @sequences, ChooseOneRandomly(@sequences_in_set);
        }
        elsif ( $type eq 'AskAll' ) {
            push @sequences, @sequences_in_set;
        }
        else {
            die "Unknown or missing type for set $set\n";
        }
    }

    return List::Util::shuffle(@sequences);
}

sub ChooseOneRandomly {
    my $count    = scalar(@_);
    my $position = int( rand() * $count );
    return $_[$position];
}

sub ShowSplashScreen {
    my $Text = $MW->Scrolled(
        'Text',
        -scrollbars => 'e',
        -width      => 80,
        -height     => 30
    )->pack( -side => 'top' );
    InsertSplashMessage($Text);
    my $button;
    $button = $MW->Button(
        -text    => 'proceed',
        -command => sub {
            $Text->destroy();
            $button->destroy();
            AskSequences();
        }
    )->pack( -side => 'top' );
}

sub InsertSplashMessage {
    my ($text) = @_;
    $text->insert( 'end', "Hi!" );
}

sub AskSequences {
    for my $sequence (@sequences_to_ask) {
        $Position++;
        our $GoOnToNextSequence = 0;
        AskSequence($sequence);
        $MW->waitVariable( \$GoOnToNextSequence );
    }
    write_config %InfoToWriteOut, "tempfile";
    exit;
}

sub AskSequence {
    my ($sequence) = @_;

    # my $Text  = $MW->Text()->pack( -side  => 'top' );
    my $frame = $MW->Frame()->pack( -side => 'top' );
    $frame->Label( -text => 'Provide next terms for sequence: ' )->pack( -side => 'left' );
    my $sequence_to_show = sprintf( "%35s", $sequence );
    my $subframe_given_sequence = $frame->Frame()->pack( -side           => 'left' );
    my $subframe_for_extension  = $frame->Frame()->pack( -side           => 'left' );
    my $temporary_label         = $subframe_for_extension->Label( -width => 35 )->pack();
    my $reveal_button;
    my $reveal_button_for_extension;

    # Times
    my $TimeOfSequenceDisplay;
    my $TimeOfUnderstanding;
    my @TimesOfChange;
    my $TimeOfFinish;
    my @next_terms_entered = map {''} 0 .. 9;

    $frame->Button(
        -text    => 'Done',
        -command => sub {
            our $GoOnToNextSequence;
            $frame->destroy();

            my $TimeOfFinish = time();
            my $UnderstandingTime = $TimeOfUnderstanding - $TimeOfSequenceDisplay;
            my @TypingTimes;
            $TypingTimes[0] = $TimesOfChange[0] ? $TimesOfChange[0] - $TimeOfUnderstanding : '?';
            for ( 1 .. 9 ) {
                if ($TimesOfChange[$_] and $TimesOfChange[$_-1]) {
                    $TypingTimes[$_] = $TimesOfChange[$_] - $TimesOfChange[ $_ - 1 ];
                } else {
                    $TypingTimes[$_] = '?';
                }
            }

            ## Times: $UnderstandingTime, @TypingTimes
            ## Sequence: @next_terms_entered
            my $info = ($InfoToWriteOut{$sequence} = {});
            $info->{position} = $Position;
            $info->{time_to_understand} = $UnderstandingTime;
            $info->{typing_times} = [@TypingTimes];
            $info->{total_typing_time} = $TimeOfFinish - $TimeOfUnderstanding;

            $GoOnToNextSequence = 1;
            }

    )->pack( -side => 'left' );

    $reveal_button = $subframe_given_sequence->Button(
        -text    => 'Reveal Sequence',
        -width   => 35,
        -command => sub {
            $reveal_button->destroy();
            $temporary_label->destroy();
            my $sequence_label = $subframe_given_sequence->Label(
                -textvariable => \$sequence_to_show,
                -width        => 35,
            )->pack( -side => 'left' );
            $TimeOfSequenceDisplay       = time();
            $reveal_button_for_extension = $subframe_for_extension->Button(
                -text    => 'I understand the sequence',
                -command => sub {
                    $reveal_button_for_extension->destroy();
                    $TimeOfUnderstanding = time();
                    for my $pos ( 0 .. 9 ) {
                        my $entry = $subframe_for_extension->Entry(
                            -textvariable    => \$next_terms_entered[$pos],
                            -width           => 3,
                            -validate        => 'key',
                            -validatecommand => sub {
                                $TimesOfChange[$pos] = time();
                                # print "VALIDATE COMMAND CALLED: $TimesOfChange[$pos]\n";
                            },
                        )->pack( -side => 'left' );
                    }
                },
                -width => 35,
            )->pack( -side => 'left' );
        }
    )->pack( -side => 'left' );

}


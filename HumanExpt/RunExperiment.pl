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

my $MW           = new MainWindow();
my $HeaderFrame  = $MW->Frame()->pack( -side => 'top' );
my $FooterFrame  = $MW->Frame()->pack( -side => 'bottom' );
my $CentralFrameCover = $MW->Frame(-height => 400)->pack( -side => 'top', -fill => 'both' );
$CentralFrameCover->Label(-height=>15)->pack(-side=>'left');
my $CentralFrame = $CentralFrameCover->Frame()->pack(-expand => 1, -fill => 'y');

SetupHeader($HeaderFrame);
ShowSplashScreen($CentralFrame);
SetupFooter($FooterFrame);

MainLoop();

sub ReadInputConfig {
    my ($filename) = @_;
    read_config $filename => my %SequenceConfig;
    my @sequences;

    while ( my ( $set, $values ) = each %SequenceConfig ) {
        my $is_extend;
        next if $set eq '';

        my $type = $values->{Type};
        my @sequences_in_set = @{ $values->{seq} } or die "No sequences for set $set!";

        if ( $set =~ /Extend/i ) {
            $is_extend = 1;
            @sequences_in_set = map { [ 'extend', $_ ] } @sequences_in_set;
        }
        elsif ( $set =~ /Variation/i ) {
            $is_extend = 0;
            @sequences_in_set = map { [ 'variation', $_ ] } @sequences_in_set;
        }
        else {
            die "Set <$set> neither 'Extend' nor 'Variation'";
        }

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
    my ($frame) = @_;
    my $Text = $frame->Scrolled(
        'Text',
        -scrollbars => 'e',
        -width      => 80,
        -height     => 10
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
    $text->tagConfigure('message', -foreground => '#0000FF');
    $text->insert( 'end', "An initial message here.", ['message'] );
}

sub AskSequences {
    for my $sequence (@sequences_to_ask) {
        $Position++;
        our $GoOnToNextSequence = 0;
        my ( $type, $seq ) = @$sequence;
        if ( $type eq 'extend' ) {
            AskSequence(
                {   sequence          => $seq,
                    message           => 'Provide next terms in the sequence',
                    sequence_stacking => 'left',
                    genre             => 'extend',
                    max_next_terms    => 10,
                    reqd_next_terms => 10,
                }
            );
        }
        else {
            AskSequence(
                {   sequence          => $seq,
                    message           => 'Provide another sequence like',
                    sequence_stacking => 'top',
                    genre             => 'variation',
                    max_next_terms  => 20,
                    reqd_next_terms => 10,
                }
            );
        }
        $MW->waitVariable( \$GoOnToNextSequence );
    }
    write_config %InfoToWriteOut, "tempfile";
    exit;
}

sub AskSequence {
    my ($opts_ref) = @_;
    my %opts_ref = %$opts_ref;

    my ( $sequence, $message, $sequence_stacking, $genre, $max_terms, $reqd_terms )
        = @opts_ref{qw{sequence message sequence_stacking genre max_next_terms reqd_next_terms}};

    ## seq, msg: $sequence, $message
    # my $Text  = $MW->Text()->pack( -side  => 'top' );
    my $frame = $CentralFrame->Frame()->pack( -side => 'top' );

    {
        my $label_frame = $frame->Frame()->pack( -side => 'top' );
        $label_frame->Label( -text => $message, -foreground => 'blue' )->pack( -side => 'left' );
    }

    my ( $subframe_given_sequence, $subframe_for_extension );

    {
        my $sequences_frame = $frame->Frame()->pack( -side => 'top' );
        $subframe_given_sequence = $sequences_frame->Frame()->pack( -side => $sequence_stacking );
        $subframe_for_extension  = $sequences_frame->Frame()->pack( -side => $sequence_stacking );
    }

    my $sequence_to_show = FormatSequenceToShow($sequence, $genre);
    my $temporary_label = $subframe_for_extension->Label( -width => 35 )->pack();
    my $reveal_button;
    my $reveal_button_for_extension;

    # Times
    my $TimeOfSequenceDisplay;
    my $TimeOfUnderstanding;
    my @TimesOfChange;
    my $TimeOfFinish;
    my @next_terms_entered = map {''} 0 .. $max_terms - 1;

    my $DoneButton;
    $DoneButton = $CentralFrame->Button(
        -text    => 'Done',
        -state   => 'disabled',
        -command => sub {
            our $GoOnToNextSequence;
            $frame->destroy();
            $DoneButton->destroy();

            my $TimeOfFinish      = time();
            my $UnderstandingTime = $TimeOfUnderstanding - $TimeOfSequenceDisplay;
            my @TypingTimes;
            $TypingTimes[0] = $TimesOfChange[0] ? $TimesOfChange[0] - $TimeOfUnderstanding : '?';
            for ( 1 .. $max_terms-1 ) {
                if ( $TimesOfChange[$_] and $TimesOfChange[ $_ - 1 ] ) {
                    $TypingTimes[$_] = $TimesOfChange[$_] - $TimesOfChange[ $_ - 1 ];
                }
                else {
                    $TypingTimes[$_] = '?';
                }
            }

            ## Times: $UnderstandingTime, @TypingTimes
            ## Sequence: @next_terms_entered
            my $info = ( $InfoToWriteOut{$sequence} = {} );
            $info->{position}           = $Position;
            $info->{time_to_understand} = $UnderstandingTime;
            $info->{typing_times}       = [@TypingTimes];
            $info->{total_typing_time}  = $TimeOfFinish - $TimeOfUnderstanding;
            $info->{genre}              = $genre;

            $GoOnToNextSequence = 1;
            }

    )->pack( -side => 'bottom', -expand => 1, -fill => 'x' );
    
    $reveal_button = $subframe_given_sequence->Button(
        -text    => 'Reveal Sequence',
        -width   => 35,
        -foreground => 'red',
        -command => sub {
            $reveal_button->destroy();
            $temporary_label->destroy();
            my $sequence_label = $subframe_given_sequence->Label(
                -textvariable => \$sequence_to_show,
                -width        => 35,
                -foreground => 'blue',
            )->pack( -side => 'left' );
            $TimeOfSequenceDisplay       = time();
            $reveal_button_for_extension = $subframe_for_extension->Button(
                -text    => 'I understand the sequence',
                -foreground => 'red',
                -command => sub {
                    $reveal_button_for_extension->destroy();
                    $TimeOfUnderstanding = time();
                    for my $pos ( 0 .. $max_terms-1 ) {
                        my $entry = $subframe_for_extension->Entry(
                            -textvariable    => \$next_terms_entered[$pos],
                            -width           => 3,
                            -validate        => 'key',
                            -validatecommand => sub {
                                $TimesOfChange[$pos] = time();
                                if ($pos == $reqd_terms - 1) {
                                    $DoneButton->configure(-state => 'normal');
                                }
                                1;
                                # print "VALIDATE COMMAND CALLED: $TimesOfChange[$pos]\n";
                            },
                        )->pack( -side => 'left' );
                        $subframe_for_extension->Label(-text=> ', ')->pack(-side => 'left');
                    }
                },
                -width => 35,
            )->pack( -side => 'left' );
        }
    )->pack( -side => 'left' );

}

sub SetupHeader {
    my ($frame) = @_;
    $frame->Label( -text => 'some stuff here', -width => 100 )->pack(-side => 'top');
}

sub SetupFooter {
    my ($frame) = @_;
    $frame->Label( -text => 'some stuff here', -width => 100 )->pack(-side => 'top');
}

sub FormatSequenceToShow{
    my ( $sequence, $genre ) = @_;
    $sequence =~ s#^\s*##;
    $sequence =~ s#\s*$##;
    my @seq = split(/\s+/, $sequence);
    $sequence = join(', ', @seq, '');
    return $genre eq 'extend' ? sprintf("%35s", $sequence) : "$sequence ...";
}


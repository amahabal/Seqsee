# Great! Synchronized to give a centered image!
use strict;
use Smart::Comments;
use Tk;
use Carp;
use Sort::Key qw(rikeysort);
use Tk::JFileDialog;

use constant {
    WIDTH      => 500,
    HEIGHT     => 55,
    BACKGROUND => 'white',
    PAGEHEIGHT => '1c',

    #FONT                     => '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4',
    FONT      => 'Lucida 14',
    MAX_TERMS => 20,
    MIN_TERMS => 10,
};

use constant { Y_CENTER => 3 + HEIGHT() / 2, };

use constant {
    GROUP_A_OPTIONS => [ -fill => '#DDDDDD' ],
    GROUP_B_OPTIONS => [ -fill => '#BBBBBB' ],
};

my $MW = new MainWindow();
my $WIDTH_PER_TERM;
my $Y_DELTA_PER_UNIT_SPAN;
my $OVAL_MINOR_AXIS_FRACTION = 30;

$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
$MW->focusmodel('active');

my $SequenceString = '{(1 1) 2 3} {1 (2 2) 3}{1 2 (3 3)}{1 ( 2 2 )3}{(1 1) 2 3}';
my $SaveFilename;

my $frame1 = $MW->Frame()->pack();
my $frame2 = $MW->Frame()->pack();
my $Entry
    = $frame1->Entry( -width => 100, -textvariable => \$SequenceString )->pack( -side => 'left' );
my $FileEntry
    = $frame2->Entry( -width => 100, -textvariable => \$SaveFilename )->pack( -side => 'left' );
my $fileDialog = $MW->JFileDialog(
    -Title => 'Select File To Save Image In',
    -FPat  => '*.eps',
    -HistFile => 'graveyard/history',
    # -HistUsePath => 1,
    -Path => 'D:/DISSERTATION/Chapters/SequenceEPS',
);
$frame2->Button(
    -text    => '...',
    -command => sub {
        $SaveFilename = undef;
        $SaveFilename = $fileDialog->Show();
        if ( defined($SaveFilename) ) {
            $SaveFilename .= '.eps' unless $SaveFilename =~ m#\.eps$#;
        }
        else {
            $SaveFilename = '';
        }
    }
)->pack(-side=>'left');
$frame2->Button(
    -text    => 'Save',
    -command => sub {
        Save() if $SaveFilename;
    }
)->pack(-side=> 'left');

$Entry->focus();

$Entry->bind(
    '<Return>' => sub {
        Show();
    }
);
$Entry->bind(
    '<KeyPress-,>' => sub {
        $OVAL_MINOR_AXIS_FRACTION--;
        Show();
    }
);
$Entry->bind(
    '<KeyPress-.>' => sub {
        $OVAL_MINOR_AXIS_FRACTION++;
        Show();
    }
);

$frame1->Button(
    -text    => 'Draw',
    -command => sub {
        Show();
    }
)->pack();

$MW->Scale(
    -orient       => 'horizontal',
    -length       => 200,
    -from         => 9,
    -to           => 50,
    -tickinterval => 1,
    -variable     => \$OVAL_MINOR_AXIS_FRACTION,
)->pack();
my $Canvas = $MW->Canvas( -height => HEIGHT() - 3, -width => WIDTH(), -background => BACKGROUND() )
    ->pack();
MainLoop();

sub Show {
    my $string = $SequenceString;
    print "Will Parse: >$SequenceString<\n";
    my ( $Elements_ref, $GroupA_ref, $GroupB_ref ) = Parse($string);

    my $ElementsCount = scalar(@$Elements_ref);
    confess "Too mant elements!" if $ElementsCount > MAX_TERMS;

    my $PretendWeHaveElements = ( $ElementsCount < MIN_TERMS ) ? MIN_TERMS: $ElementsCount;
    $WIDTH_PER_TERM = WIDTH / ( $PretendWeHaveElements + 1 );
    $Y_DELTA_PER_UNIT_SPAN
        = ( HEIGHT() * $OVAL_MINOR_AXIS_FRACTION * 0.1 ) / ( 2 * $PretendWeHaveElements ),

        $Canvas->delete('all');
    for (@$GroupA_ref) {
        DrawGroup( @$_, GROUP_A_OPTIONS );
    }
    for (@$GroupB_ref) {
        DrawGroup( @$_, GROUP_B_OPTIONS );
    }
    DrawElements($Elements_ref);

    #my $distance_from_edge = 2;
    #$Canvas->createLine(0, $distance_from_edge, WIDTH(), $distance_from_edge);
    #$Canvas->createLine(0, HEIGHT - $distance_from_edge, WIDTH(), HEIGHT - $distance_from_edge);
}

sub DrawElements {
    my ($Elements_ref) = @_;
    my $x_pos = $WIDTH_PER_TERM * 0.5;
    for my $elt (@$Elements_ref) {
        $Canvas->createText(
            $x_pos, Y_CENTER,
            -text   => $elt,
            -font   => FONT,
            -fill   => 'black',
            -anchor => 'center',
        );
        $x_pos += $WIDTH_PER_TERM;
    }
}

sub DrawGroup {
    my ( $start, $end, $options_ref ) = @_;
    my $span = $end - $start;
    my ( $x1, $x2 ) = ( $WIDTH_PER_TERM * ( $start + 0.1 ), $WIDTH_PER_TERM * ( $end - 0.1 ) );
    my $y_delta = $span * $Y_DELTA_PER_UNIT_SPAN;
    my ( $y1, $y2 ) = ( Y_CENTER() - $y_delta, Y_CENTER() + $y_delta );
    $Canvas->createOval( $x1, $y1, $x2, $y2, @$options_ref );
}

{
    my @GroupA;
    my @GroupB;

    sub Parse {
        my ($string) = @_;
        @GroupA = @GroupB = ();
        my @tokens = Tokenize($string);
        my @Elements = grep {m#\d#} @tokens;
        ReadGroups( \@tokens, '{', '}', \@GroupA );
        ReadGroups( \@tokens, '[', ']', \@GroupA );
        ReadGroups( \@tokens, '(', ')', \@GroupB );
        ReadGroups( \@tokens, '<', '>', \@GroupB );

        ### GroupA: @GroupA
        ### GroupB: @GroupB

        @GroupA = rikeysort { $_->[1] - $_->[0] } @GroupA;
        @GroupB = rikeysort { $_->[1] - $_->[0] } @GroupB;

        ### GroupA: @GroupA
        ### GroupB: @GroupB
        return ( \@Elements, \@GroupA, \@GroupB );
    }

    sub Tokenize {
        my ($string) = @_;
        print $string, "\n";
        $string =~ s#,# #g;
        print $string, "\n";
        $string =~ s#([\(\)\[\]\<\>\{\}])# $1 #g;
        $string =~ s#^\s*##;
        $string =~ s#\s*$##;
        print $string, "\n";
        return split( /\s+/, $string );
    }

    sub ReadGroups {
        my ( $tokens_ref, $start_token, $end_token, $groups_set ) = @_;
        my $stack_size = 0;
        my @stack;
        my $element_count = 0;
        for my $token (@$tokens_ref) {
            if ( $token eq $start_token ) {
                $stack_size++;
                push @stack, $element_count;
            }
            elsif ( $token eq $end_token ) {
                die "Mismatched $end_token" unless $stack_size;
                my $group_start = pop(@stack);
                push @$groups_set, [ $group_start, $element_count ];
                $stack_size--;
            }
            elsif ( $token =~ m#^ \-? \d+ #x ) {
                $element_count++;
            }
        }
        if ($stack_size) {
            die "Mismatched $start_token";
        }
    }
}

sub Save {
    my $filename = $SaveFilename;
    die "File exists. Fix this bug first." if -e $filename;
    $Canvas->postscript( -file => $filename, -pageheight => PAGEHEIGHT, -height => HEIGHT );
}

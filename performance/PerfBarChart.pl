use 5.10.0;
use strict;
use lib 'performance';
use Statistics::Basic qw{:all};
use Sort::Key qw(rikeysort);
use Exception::Class ( 'Y_TOO_BIG' => {} );

use lib 'genlib';
use Global;
use List::Util qw{min max sum};
use Time::HiRes qw{time};
use Getopt::Long;
use Storable;
use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Config::Std;
use Carp;

use Tk;
my $MW = new MainWindow();

use FilterableResultSets;

my %options;
GetOptions \%options, "graph_spec=s";
read_config $options{graph_spec} => my %Config;

my $CLUSTER_COUNT = $Config{General}{ClusterCount} ||= 1;
my $SEQUENCE_COUNT = scalar( @{ $Config{Sequences}{seq} } );

my $FRS = new FilterableResultSets(
    { sequences_filename => $Config{General}{TestSet} } );

my @GeneralFilters;
if (   exists $Config{General}{MinVersion}
    or exists $Config{General}{MaxVersion} )
{
    my $minv = $Config{General}{MinVersion} // '0:0';
    my $maxv = $Config{General}{MaxVersion} // '100000:999';
    push @GeneralFilters, [ 'version', $minv, $maxv ];
}
if ( exists $Config{General}{OnlyTheseFeatures} ) {
    push @GeneralFilters, [ 'features', $Config{General}{OnlyTheseFeatures} ];
}

my @ResultSets;
for my $cluster_num ( 1 .. $CLUSTER_COUNT ) {
    my $cluster_config = $Config{"cluster_$cluster_num"} || {};
    my @cluster_specific_filters;
    if (   exists $cluster_config->{MinVersion}
        or exists $cluster_config->{MaxVersion} )
    {
        my $minv = $cluster_config->{MinVersion} // '0:0';
        my $maxv = $cluster_config->{MaxVersion} // '100000:999';
        push @cluster_specific_filters, [ 'version', $minv, $maxv ];
    }

    if ( exists $cluster_config->{OnlyTheseFeatures} ) {
        push @cluster_specific_filters,
          [ 'features', $cluster_config->{OnlyTheseFeatures} ];
    }

    push @ResultSets,
      FilterableResults->new(
        {
            result_set => $FRS,
            filters    => [ @GeneralFilters, @cluster_specific_filters ]
        }
      );
}

my $MARGIN                = 25;
my $CHART_SEQ_SEPARATION  = 15;
my $CHART_BAR_HEIGHT      = 30;
my $CHART_BAR_SEPARATION  = 10;
my $SEQUENCE_HEIGHT       = 30;
my $SEQUENCE_SEPARATION   = 10;
my $PERCENT_CORRECT_WIDTH = 150;
my $NUM_CORRECT_WIDTH     = 40;
my $CODELET_COUNT_WIDTH   = 300;
my $HORIZONTAL_SEPARATION = 30;
my $HORIZONTAL_OFFSET     = 30;

my $Y_OFFSET_FOR_SEQUENCES =
  $MARGIN +
  $CHART_SEQ_SEPARATION +
  $SEQUENCE_COUNT * ( $CHART_BAR_SEPARATION + $CHART_BAR_HEIGHT );
my $UNIT_CANVAS_HEIGHT =
  $CHART_BAR_HEIGHT +
  $CHART_BAR_SEPARATION +
  $SEQUENCE_HEIGHT +
  $SEQUENCE_SEPARATION;

my $SUB_BAR_SEPARATION = 3;
my $SUB_BAR_HEIGHT =
  ( $CHART_BAR_HEIGHT - ( $CLUSTER_COUNT - 1 ) * $SUB_BAR_SEPARATION ) /
  $CLUSTER_COUNT;
my $SUB_BAR_UNIT_OFFSET = $SUB_BAR_SEPARATION + $SUB_BAR_HEIGHT;

my $EFFECTIVE_HEIGHT =
  $SEQUENCE_COUNT * $UNIT_CANVAS_HEIGHT + $CHART_SEQ_SEPARATION;
my $EFFECTIVE_WIDTH =
  $HORIZONTAL_OFFSET +
  $PERCENT_CORRECT_WIDTH +
  $NUM_CORRECT_WIDTH +
  $CODELET_COUNT_WIDTH +
  2 * $HORIZONTAL_SEPARATION;
my $WIDTH  = $EFFECTIVE_WIDTH + 2 * $MARGIN;
my $HEIGHT = $EFFECTIVE_HEIGHT + 2 * $MARGIN;

my $MAX_TERMS = 25;
my $MIN_TERMS = 10;
my $OVAL_MINOR_AXIS_FRACTION = 15;
my $OVAL_MINOR_AXIS_MIN = 10;
my $WIDTH_PER_TERM;
my $Y_DELTA_PER_UNIT_SPAN;

my %ARROW_ANCHORS;
sub WIDTH {
    return $EFFECTIVE_WIDTH - $HORIZONTAL_OFFSET;
}

sub HEIGHT {
    return $SEQUENCE_HEIGHT;
}

sub Y_CENTER {
    $SEQUENCE_HEIGHT / 2;
}
    

use constant {
    GROUP_A_OPTIONS => [ -fill => '#DDDDDD' ],
    GROUP_B_OPTIONS => [ -fill => '#BBBBBB' ],
        FONT => 'Lucida 14',
};

sub BarCoordToCanvasCoord {
    my ( $bar_num, $x, $y ) = @_;
    my $new_y =
      $bar_num * ( $CHART_BAR_HEIGHT + $CHART_BAR_SEPARATION ) + $MARGIN + $y;
    return ( $MARGIN + $x, $new_y );
}

sub SeqCoordToCanvasCoord {
    my ( $seq_num, $x, $y ) = @_;
    my $new_y =
      $Y_OFFSET_FOR_SEQUENCES +
      $seq_num * ( $SEQUENCE_HEIGHT + $SEQUENCE_SEPARATION ) +
      $y;
    return ( $MARGIN + $x, $new_y );
}

sub GraphSpecSeqToTestSetSeq {
    my ( $gs_seq, $aref ) = @_;
    my ($revealed_part) = split( /\|/, $gs_seq );
    $revealed_part =~ s#\D# #g;
    $revealed_part =~ s#^\s*##;
    $revealed_part =~ s#\s*$##;
    $revealed_part =~ s#\s+# #g;

    for my $seq (@$aref) {
        ### revealed_part, $seq: $revealed_part, $seq
        return $seq if $seq =~ m{^$revealed_part\|};
    }

    die "<$gs_seq> not present!";
}

my $Canvas = $MW->Canvas(
    -background => '#FFFFFF',
    -height     => $HEIGHT,
    -width      => $WIDTH
)->pack( -side => 'top' );

$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
$MW->focusmodel('active');

DrawChart();
DrawSequences();

MainLoop();

sub DrawChart {
    my $text_counter            = 'a';
    my $seq_num                 = 0;
    my $test_set_sequences_aref = $FRS->get_sequences_to_track_aref();
    my @ResultSetsIndexedBySeq =
      map { $_->get_results_by_sequence } @ResultSets;

    for my $seq ( @{ $Config{Sequences}{seq} } ) {
        my $eff_seq =
          GraphSpecSeqToTestSetSeq( $seq, $test_set_sequences_aref );
        my @ResForThisSequence = map { $_->{$eff_seq} } @ResultSetsIndexedBySeq;

        $Canvas->createText(
            BarCoordToCanvasCoord( $seq_num, 20, $CHART_BAR_HEIGHT / 2 ),
            -text   => $text_counter,
            -anchor => 'e'
        );

        my $subcounter = 0;
        for my $stats (@ResForThisSequence) {
            my $color    = ClusterNumToColor($subcounter);
            my $y_offset = ClusterNumToYOffset($subcounter);
            my $y_bottom = $y_offset + $SUB_BAR_HEIGHT;

            # Draw % Correct
            my $x1 = $HORIZONTAL_OFFSET;
            my $x2 =
              $HORIZONTAL_OFFSET +
              $PERCENT_CORRECT_WIDTH * $stats->get_success_percentage() / 100;
            $Canvas->createRectangle(
                BarCoordToCanvasCoord( $seq_num, $x1, $y_offset ),
                BarCoordToCanvasCoord( $seq_num, $x2, $y_bottom ),
                -fill => $color
            );

            # Num correct
            $Canvas->createText(
                BarCoordToCanvasCoord(
                    $seq_num,
                    $HORIZONTAL_OFFSET +
                      $PERCENT_CORRECT_WIDTH +
                      $HORIZONTAL_SEPARATION,
                    $y_offset + $SUB_BAR_HEIGHT / 2
                ),
                -text   => $stats->get_successful_count(),
                -anchor => 'w'
            );

            # Draw Time Taken
            my $MaxSteps = 20000;    # Fix?
            $x1 = $EFFECTIVE_WIDTH - $CODELET_COUNT_WIDTH;
            $x2 =
              $x1 +
              $CODELET_COUNT_WIDTH *
              ( $stats->get_avg_time_to_success() / $MaxSteps );
            $Canvas->createRectangle(
                BarCoordToCanvasCoord( $seq_num, $x1, $y_offset ),
                BarCoordToCanvasCoord( $seq_num, $x2, $y_bottom ),
                -fill => $color
            );
            $subcounter++;
        }

        $text_counter++;
        $seq_num++;
    }
}

sub DrawSequences {
    my $text_counter = 'a';
    my $seq_num      = 0;
    for my $seq ( @{ $Config{Sequences}{seq} } ) {
        $Canvas->createText(
            SeqCoordToCanvasCoord( $seq_num, 0, 0 ),
            -text   => $text_counter,
            -anchor => 'nw'
        );

        Show( $seq_num, $seq, 0 );
        $text_counter++;
        $seq_num++;
    }
}

sub ClusterNumToYOffset {
    my ($cnum) = @_;
    $cnum * $SUB_BAR_UNIT_OFFSET;
}

sub ClusterNumToColor {
    my ($cnum) = @_;
    return '#FF0000';
}

{
    my @GroupA;
    my @GroupB;
    my @BarLines;

    sub Parse {
        my ($string) = @_;
        @GroupA = @GroupB = ();
        my @tokens = Tokenize($string);
        my @Elements = grep { m#\d# } @tokens;
        ReadGroups( \@tokens, '{', '}', \@GroupA );
        ReadGroups( \@tokens, '[', ']', \@GroupA );
        ReadGroups( \@tokens, '(', ')', \@GroupB );
        ReadGroups( \@tokens, '<', '>', \@GroupB );
        @BarLines = ();
        ReadBarLines( \@tokens, \@BarLines );

        ### GroupA: @GroupA
        ### GroupB: @GroupB

        @GroupA = rikeysort { $_->[1] - $_->[0] } @GroupA;
        @GroupB = rikeysort { $_->[1] - $_->[0] } @GroupB;

        ### GroupA: @GroupA
        ### GroupB: @GroupB
        return ( \@Elements, \@GroupA, \@GroupB, \@BarLines );
    }

    sub Tokenize {
        my ($string) = @_;
        print $string, "\n";
        $string =~ s#,# #g;
        print $string, "\n";
        $string =~ s#([\(\)\[\]\<\>\{\}\|])# $1 #g;
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

    sub ReadBarLines {
        my ( $tokens_ref, $barlines_ref ) = @_;
        ### In ReadBarLines:
        my $elements_seen = 0;
        for my $token (@$tokens_ref) {
            if ( $token eq '|' ) {
                ### Token: $token
                push @$barlines_ref, $elements_seen;
            }
            elsif ( $token =~ m#^ \-? \d+ #x ) {
                $elements_seen++;
            }
        }
    }
}

sub Show {
    my ( $seq_num, $SequenceString, $IS_MOUNTAIN ) = @_;
    %ARROW_ANCHORS = ();
    if ($IS_MOUNTAIN) {
        ShowMountain();
        return;
    }
    my $string = $SequenceString;

    print "Will Parse: >$SequenceString<\n";
    my ( $Elements_ref, $GroupA_ref, $GroupB_ref ) = Parse($string);

    my $ElementsCount = scalar(@$Elements_ref);
    confess "Too mant elements!" if $ElementsCount > $MAX_TERMS;

    my $PretendWeHaveElements =
      ( $ElementsCount < $MIN_TERMS ) ? $MIN_TERMS : $ElementsCount;
    $WIDTH_PER_TERM = WIDTH() / ( $PretendWeHaveElements + 1 );
    $Y_DELTA_PER_UNIT_SPAN
        = ( HEIGHT() * $OVAL_MINOR_AXIS_FRACTION * 0.1 ) /
      ( 2 * $PretendWeHaveElements );

    for (@$GroupA_ref) {
        DrawGroup( $seq_num, @$_, 3, GROUP_A_OPTIONS );
    }
    for (@$GroupB_ref) {
        DrawGroup( $seq_num, @$_, 0, GROUP_B_OPTIONS );
    }
    DrawElements( $seq_num, $Elements_ref );
    DrawArrows($seq_num);

#my $distance_from_edge = 2;
#$Canvas->createLine(0, $distance_from_edge, WIDTH(), $distance_from_edge);
#$Canvas->createLine(0, HEIGHT - $distance_from_edge, WIDTH(), HEIGHT - $distance_from_edge);
}

sub DrawElements {
    my ( $seq_num, $Elements_ref ) = @_;
    my $label = 'a';
    my $x_pos = 3 + $WIDTH_PER_TERM * 0.5;
    my $count = 0;
    for my $elt (@$Elements_ref) {
        $Canvas->createText(
            SeqCoordToCanvasCoord( $seq_num, $x_pos + $HORIZONTAL_OFFSET, $SEQUENCE_HEIGHT / 2 ),
            -text   => $elt,
            -font   => FONT,
            -fill   => 'black',
            -anchor => 'center',
        );

        # $ARROW_ANCHORS{"$count"} //= [$x_pos, Y_CENTER - 10 ];
        $count++;
        $x_pos += $WIDTH_PER_TERM;
    }
}

sub DrawArrows {
    my $Arrows;
    $Arrows =~ s#\s##g;
    return unless $Arrows;
    my @pieces = split( /;/, $Arrows );
    for my $piece (@pieces) {
        $piece =~ m#^ ([\d,]+) : ([\d,]+) $#x
          or confess
          "Cannot parse $Arrows (specifically, the piece >>$piece<<)";
        my ( $left, $right ) = ( $1, $2 );
        my $left_arrow_pos = $ARROW_ANCHORS{$left} or confess "No group $left";
        my $right_arrow_pos = $ARROW_ANCHORS{$right}
          or confess "No group $right";
        my ( $x1, $y1, $x2, $y2 ) = ( @$left_arrow_pos, @$right_arrow_pos );
        $Canvas->createLine(
            $x1, $y1,
            ( $x1 + $x2 ) / 2,
            Y_CENTER - 30,
            $x2, $y2,
            -arrowshape => [ 8, 12, 10 ],
            -smooth     => 1,
            -arrow      => 'last',
            -width      => 2,
            -fill       => 'black',
        );
    }
}

sub DrawGroup {
    my ( $seq_num, $start, $end, $extra_width, $options_ref ) = @_;
    my $span = $end - $start;
    my ( $x1, $x2 ) = (
        3 + $WIDTH_PER_TERM * ( $start + 0.1 ) - $extra_width,
        3 + $WIDTH_PER_TERM * ( $end - 0.1 ) + $extra_width
    );
    my $y_delta =
      $OVAL_MINOR_AXIS_MIN + $extra_width + $span * $Y_DELTA_PER_UNIT_SPAN;

    #if ( $y_delta > Y_CENTER() - 7 ) {    # Center is off a bit.
    #    $OVAL_MINOR_AXIS_FRACTION--;
    #    Y_TOO_BIG->throw();
    #}

    my ( $y1, $y2 ) = ( Y_CENTER() - $y_delta, Y_CENTER() + $y_delta );
    $Canvas->createOval(
        SeqCoordToCanvasCoord( $seq_num, $x1 + $HORIZONTAL_OFFSET, $y1 ),
        SeqCoordToCanvasCoord( $seq_num, $x2 + $HORIZONTAL_OFFSET, $y2 ),
        @$options_ref
    );
    my $upto = $end - 1;
    say "Drew >>$start,$upto<<";
    $ARROW_ANCHORS{"$start,$upto"} //= [ ( $x1 + $x2 ) / 2, $y1 ];
}

use 5.10.0;
use strict;
use lib 'performance';
use Statistics::Basic qw{:all};
use Sort::Key qw(rikeysort);
use Exception::Class ( 'Y_TOO_BIG' => {} );

use lib 'genlib';
use Global;
use List::Util qw{min max sum first};
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
GetOptions \%options, "graph_spec=s", "outfile=s";
read_config $options{graph_spec} => my %Config;

my $CLUSTER_COUNT              = $Config{General}{ClusterCount} ||= 1;
my $SEQUENCE_COUNT             = scalar( @{ $Config{Sequences}{seq} } );
my $SEQUENCES_TO_DISPLAY_COUNT = $SEQUENCE_COUNT;

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
my @ClusterConfigs;

for my $cluster_num ( 1 .. $CLUSTER_COUNT ) {
    my $cluster_config = $Config{"cluster_$cluster_num"} || {};
    push @ClusterConfigs, $cluster_config;

    my $is_human_data = 0;

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

    if ( $cluster_config->{Human} ) {
        $is_human_data = 1;
        push @cluster_specific_filters, [ 'features', 'human' ];
    }

    push @ResultSets,
      FilterableResults->new(
        {
            result_set    => $FRS,
            filters       => [ @GeneralFilters, @cluster_specific_filters ],
            is_human_data => $is_human_data,
        }
      );
}

#==== HORIZONTAL
my $FIG_WIDTH                = 600;
my $FIG_L_MARGIN             = 20;
my $FIG_R_MARGIN             = 20;
my $CHART_CHART_SEPARATION   = 20;
my $CHART_L_MARGIN           = 10;
my $CHART_R_MARGIN           = 10;
my $INTER_CLUSTER_SEPARATION = 10;
my $INTER_BAR_SEPARATION     = 5;
my $MAX_BAR_WIDTH            = 10;

#=== VERTICAL
my $FIG_T_MARGIN              = 20;
my $FIG_B_MARGIN              = 20;
my $INTER_SEQUENCE_SEPARATION = 15;
my $SEQUENCE_HEIGHT = 20;
my $SEQUENCES_CHART_SEPARATION = 20;
my $CHART_T_MARGIN             = 20;
my $CHART_B_MARGIN             = 20;
my $CHART_HEIGHT               = 100;

#=== HORIZONTAL CALCULATED
my $EFFECTIVE_FIG_WIDTH = $FIG_WIDTH - $FIG_L_MARGIN - $FIG_R_MARGIN;
my $CHART_WIDTH        = ( $EFFECTIVE_FIG_WIDTH - $CHART_CHART_SEPARATION ) / 2;
my $SEQUENCES_H_OFFSET = $FIG_L_MARGIN;
my $CHART1_H_OFFSET    = $FIG_L_MARGIN;
my $CHART2_H_OFFSET = $CHART1_H_OFFSET + $CHART_WIDTH + $CHART_CHART_SEPARATION;
my $EFFECTIVE_CHART_WIDTH = $CHART_WIDTH - $CHART_L_MARGIN - $CHART_R_MARGIN;
my $MAX_CLUSTER_WIDTH =
  ( $EFFECTIVE_CHART_WIDTH -
      $INTER_CLUSTER_SEPARATION * ( $SEQUENCE_COUNT - 1 ) ) / $SEQUENCE_COUNT;
my $BAR_WIDTH = min( $MAX_BAR_WIDTH,
    ( $MAX_CLUSTER_WIDTH - $INTER_BAR_SEPARATION * ( $CLUSTER_COUNT - 1 ) ) /
      $CLUSTER_COUNT );
my $CLUSTER_WIDTH =
  $CLUSTER_COUNT * ( $BAR_WIDTH + $INTER_BAR_SEPARATION ) -
  $INTER_BAR_SEPARATION;

my $HORIZONTAL_FIRST_BAR_IN_CLUSTER_OFFSET =
  ( $MAX_CLUSTER_WIDTH - $CLUSTER_WIDTH ) / 2;

#=== VERTICAL CALCULATED
my $SEQUENCES_V_OFFSET = $FIG_T_MARGIN;
my $SEQUENCES_HEIGHT =
  ( $SEQUENCE_HEIGHT * $SEQUENCES_TO_DISPLAY_COUNT ) +
  ( $INTER_SEQUENCE_SEPARATION * ( $SEQUENCES_TO_DISPLAY_COUNT - 1 ) );
my $SEQUENCES_BOTTOM = $SEQUENCES_HEIGHT + $SEQUENCES_V_OFFSET;
my $CHART_V_OFFSET   = $SEQUENCES_BOTTOM + $SEQUENCES_CHART_SEPARATION;
my $CHART_BOTTOM     = $CHART_V_OFFSET + $CHART_HEIGHT;
my $MAX_BAR_HEIGHT   = $CHART_HEIGHT - $CHART_T_MARGIN - $CHART_B_MARGIN;
my $BAR_BOTTOM       = $CHART_BOTTOM - $CHART_B_MARGIN;
my $FIG_HEIGHT       = $CHART_BOTTOM + $FIG_B_MARGIN;

sub HorizontalClusterOffset {
    my ( $chart_num, $sequence_num ) = @_;
    my $chart_offset =
      ( $chart_num == 1 ) ? $CHART1_H_OFFSET : $CHART2_H_OFFSET;
    return $chart_offset + $CHART_L_MARGIN +
      $sequence_num * ( $MAX_CLUSTER_WIDTH + $INTER_CLUSTER_SEPARATION );
}

sub HorizontalClusterCenterOffset {
    my ( $chart_num, $sequence_num ) = @_;
    HorizontalClusterOffset( $chart_num, $sequence_num ) +
      $MAX_CLUSTER_WIDTH / 2;
}

sub HorizontalBarOffset {
    my ( $chart_num, $sequence_num, $cluster_num ) = @_;
    HorizontalClusterOffset( $chart_num, $sequence_num ) +
      $HORIZONTAL_FIRST_BAR_IN_CLUSTER_OFFSET +
      $cluster_num * ( $BAR_WIDTH + $INTER_BAR_SEPARATION );
}

sub BarCoordinateToFigCoordinate {

    # $x $y each in [0,1]. y=0 is bottom.
    my ( $chart_num, $sequence_num, $cluster_num, $x, $y ) = @_;
    my $horiz_offset =
      HorizontalBarOffset( $chart_num, $sequence_num, $cluster_num );
    my $x_ret = $horiz_offset + $x * $BAR_WIDTH;
    my $y_ret = $BAR_BOTTOM - $y * $MAX_BAR_HEIGHT;
    return ( $x_ret, $y_ret );
}

my $MAX_TERMS                = 35;
my $MIN_TERMS                = 10;
my $OVAL_MINOR_AXIS_FRACTION = 15;
my $OVAL_MINOR_AXIS_MIN      = 10;
my $WIDTH_PER_TERM;
my $Y_DELTA_PER_UNIT_SPAN;
my $FADE_AFTER;
my %ARROW_ANCHORS;

sub WIDTH {
    return $EFFECTIVE_FIG_WIDTH;
}

sub HEIGHT {
    return $SEQUENCE_HEIGHT;
}

sub Y_CENTER {
    $SEQUENCE_HEIGHT / 2;
}

use constant {
    GROUP_A_OPTIONS     => [ -fill    => '#DDDDDD' ],
    GROUP_B_OPTIONS     => [ -fill    => '#BBBBBB' ],
    FADED_GROUP_OPTIONS => [ -stipple => 'gray25', -width => 0 ],
    DISTRACTOR_OPTIONS  => [ -outline => '#0000FF', -width => 4 ],

    SCALE_LINE_OPTIONS => [ -fill => '#EEEEEE' ],
    SCALE_TEXT_OPTIONS => [ -font => 'Lucida 10', -fill => '#CCCCCC' ],
    FONT => 'Lucida 14',
};


sub SeqCoordToCanvasCoord {
    my ( $seq_num, $x, $y ) = @_;
    my $new_y =
      $SEQUENCES_V_OFFSET +
      $seq_num * ( $SEQUENCE_HEIGHT + $INTER_SEQUENCE_SEPARATION ) +
      $y;
    return ( $SEQUENCES_H_OFFSET + $x, $new_y );
}

sub GraphSpecSeqToTestSetSeq {
    my ( $gs_seq, $aref ) = @_;
    my ($revealed_part) = split( /\|/, $gs_seq );
    $revealed_part =~ s#\D# #g;
    $revealed_part =~ s#^\s*##;
    $revealed_part =~ s#\s*$##;
    $revealed_part =~ s#\s+# #g;

    for my $seq (@$aref) {
        ## revealed_part, $seq: $revealed_part, $seq
        return $seq if $seq =~ m{^$revealed_part\|};
    }

    return;
}

my $Canvas = $MW->Canvas(
    -background => '#FFFFFF',
    -height     => $FIG_HEIGHT,
    -width      => $FIG_WIDTH
)->pack( -side => 'top' );

$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
$MW->focusmodel('active');

DrawChart();
DrawSequences();
if ( my $outfile = $options{outfile} ) {
    $MW->Button(
        -text    => 'Save',
        -command => sub {
            $Canvas->postscript(
                -file       => $outfile,
                -pageheight => '10c',
                -height     => $FIG_HEIGHT,
            );
            exit;
          }

    )->pack( -side => 'top' );
}
MainLoop();

sub DrawChart {
    my $text_counter            = 'a';
    my $seq_num                 = 0;
    my $test_set_sequences_aref = $FRS->get_sequences_to_track_aref();
    my @ResultSetsIndexedBySeq =
      map { $_->get_results_by_sequence } @ResultSets;

    ## MaxSteps
    my $MaxSteps;
    for my $seq ( @{ $Config{Sequences}{seq} } ) {
        my $eff_seq = GraphSpecSeqToTestSetSeq( $seq, $test_set_sequences_aref )
          or die "$seq not present!";
        my @ResForThisSequence = map { $_->{$eff_seq} } @ResultSetsIndexedBySeq;

        for my $stats (@ResForThisSequence) {
            my $avg_time_to_success = $stats->get_avg_time_to_success();
            $MaxSteps = $avg_time_to_success
              if $avg_time_to_success > $MaxSteps;
        }
    }

    $MaxSteps = first { $_ > $MaxSteps } (
        500,
        ( map { $_ * 1000 } ( 1 .. 10 ) ),
        ( map { $_ * 5000 } ( 3 .. 100 ) )
    );

    DrawPercentCorrectScale();
    ## MaxSteps: $MaxSteps
    DrawCodeletCountScale($MaxSteps);
    ## Scales Drawn

    for my $seq ( @{ $Config{Sequences}{seq} } ) {
        my $eff_seq = GraphSpecSeqToTestSetSeq( $seq, $test_set_sequences_aref )
          or die "$seq not present!";
        my @ResForThisSequence = map { $_->{$eff_seq} } @ResultSetsIndexedBySeq;

        for my $chart_num ( 1, 2 ) {
            $Canvas->createText(
                HorizontalClusterCenterOffset( $chart_num, $seq_num ),
                $CHART_BOTTOM - 5,
                -text   => $text_counter,
                -anchor => 's'
            );
        }

        my $subcounter = 0;
        for my $stats (@ResForThisSequence) {
            my $color = ClusterNumToColor($subcounter);

            # Draw % Correct
            my $fraction_correct = $stats->get_success_percentage() / 100;
            $Canvas->createRectangle(
                BarCoordinateToFigCoordinate( 1, $seq_num, $subcounter, 0, 0 ),
                BarCoordinateToFigCoordinate(
                    1, $seq_num, $subcounter, 1, $fraction_correct
                ),
                -fill => $color
            );

            # Num correct
            $Canvas->createText(
                BarCoordinateToFigCoordinate(
                    1, $seq_num, $subcounter, 0.5, $fraction_correct
                ),
                -text   => $stats->get_successful_count(),
                -anchor => 's'
            );

            # Draw Time Taken
            my $fraction_of_max_steps =
              $stats->get_avg_time_to_success() / $MaxSteps;
            $Canvas->createRectangle(
                BarCoordinateToFigCoordinate( 2, $seq_num, $subcounter, 0, 0 ),
                BarCoordinateToFigCoordinate(
                    2, $seq_num, $subcounter, 1, $fraction_of_max_steps
                ),
                -fill => $color
            );
            $subcounter++;
        }

        $text_counter++;
        $seq_num++;
    }
}

sub DrawSequences {
    ## DrawSequences:
    my $text_counter = 'a';
    my $seq_num      = 0;
    for my $seq ( @{ $Config{Sequences}{seq} } ) {
        $Canvas->createText(
            SeqCoordToCanvasCoord( $seq_num, 20, $SEQUENCE_HEIGHT / 2 ),
            -text   => $text_counter,
            -anchor => 'e'
        );

        my $sequence_to_show = $seq;
        my @distractor;

        my $seq_specific_config = $Config{ 'Sequence_' . ( $seq_num + 1 ) };
        if ($seq_specific_config) {
            my $distractor = $seq_specific_config->{distractor};
            if ( ref $distractor ) {
                @distractor = @$distractor;
            }
            elsif ($distractor) {
                @distractor = ($distractor);
            }

            if ( my $instead = $seq_specific_config->{ShowInstead} ) {
                $sequence_to_show = $instead;
            }

        }

        Show( $seq_num, $sequence_to_show, 0 );
        for my $dist (@distractor) {
            my ( $start, $end ) = split( ' ', $dist );
            DrawGroup( $seq_num, $start, $end, 3, DISTRACTOR_OPTIONS );
        }

        $text_counter++;
        $seq_num++;
    }
}

sub ClusterNumToColor {
    my ($cnum) = @_;
    my $cluster_config = $ClusterConfigs[$cnum];
    return '#00FF00' if $cluster_config->{Human};
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
        my @Elements = grep { m#\d|\.# } @tokens;
        ReadGroups( \@tokens, '{', '}', \@GroupA );
        ReadGroups( \@tokens, '[', ']', \@GroupA );
        ReadGroups( \@tokens, '(', ')', \@GroupB );
        ReadGroups( \@tokens, '<', '>', \@GroupB );
        @BarLines = ();
        ReadBarLines( \@tokens, \@BarLines );

        ## GroupA: @GroupA
        ## GroupB: @GroupB

        @GroupA = rikeysort { $_->[1] - $_->[0] } @GroupA;
        @GroupB = rikeysort { $_->[1] - $_->[0] } @GroupB;

        ## GroupA: @GroupA
        ## GroupB: @GroupB
        return ( \@Elements, \@GroupA, \@GroupB, \@BarLines );
    }

    sub Tokenize {
        my ($string) = @_;
        print $string, "\n";
        $string =~ s#,# #g;
        print $string, "\n";
        $string =~ s#([\(\)\[\]\<\>\{\}\|])# $1 #g;
        $string =~ s#\.\.\.# ... #g;
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
            elsif ( $token =~ m#^ \-? \d+ | \.#x ) {
                $element_count++;
            }
        }
        if ($stack_size) {
            die "Mismatched $start_token";
        }
    }

    sub ReadBarLines {
        my ( $tokens_ref, $barlines_ref ) = @_;
        ## In ReadBarLines:
        my $elements_seen = 0;
        for my $token (@$tokens_ref) {
            if ( $token eq '|' ) {
                ## Token: $token
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
    my ( $Elements_ref, $GroupA_ref, $GroupB_ref, $BarLines_ref ) =
      Parse($string);

    $FADE_AFTER = $BarLines_ref->[0];
    my $ElementsCount = scalar(@$Elements_ref);
    confess "Too mant elements!" if $ElementsCount > $MAX_TERMS;

    my $PretendWeHaveElements =
      ( $ElementsCount < $MIN_TERMS ) ? $MIN_TERMS : $ElementsCount;
    $WIDTH_PER_TERM = WIDTH() / ( $PretendWeHaveElements + 1 );
    $Y_DELTA_PER_UNIT_SPAN =
      ( HEIGHT() * $OVAL_MINOR_AXIS_FRACTION * 0.1 ) /
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
        my $fill = ( $count >= $FADE_AFTER ) ? '#CCCCCC' : 'black';
        $Canvas->createText(
            SeqCoordToCanvasCoord(
                $seq_num,
                $x_pos,
                $SEQUENCE_HEIGHT / 2
            ),
            -text   => $elt,
            -font   => FONT,
            -fill   => $fill,
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
            Y_CENTER -30,
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
    my $faded = 1 if $end > $FADE_AFTER;
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

    my @options = @$options_ref;
    push @options, @{ FADED_GROUP_OPTIONS() } if $faded;
    $Canvas->createOval(
        SeqCoordToCanvasCoord( $seq_num, $x1 , $y1 ),
        SeqCoordToCanvasCoord( $seq_num, $x2 , $y2 ),
        @options
    );
    my $upto = $end - 1;
    # say "Drew >>$start,$upto<<";
    $ARROW_ANCHORS{"$start,$upto"} //= [ ( $x1 + $x2 ) / 2, $y1 ];
}

 sub DrawPercentCorrectScale {
     my ( $left, $bottom ) = BarCoordinateToFigCoordinate(1, 0, 0, -1, 0);
     my $top = $bottom - $MAX_BAR_HEIGHT;
     my ($right) = BarCoordinateToFigCoordinate(1, $SEQUENCE_COUNT - 1, $CLUSTER_COUNT, 1.1, 0);

     my $height_per_percent = $MAX_BAR_HEIGHT / 100;

     for ( 0, 25, 50, 75, 100 ) {
         DrawScaleLine(
             {
                 left    => $left,
                 right => $right,
                 label  => $_ . '%',
                 y   => $bottom - $_ * $height_per_percent
             }
         );
     }
 }

 sub DrawCodeletCountScale {
     my ($MaxSteps) = @_;
     my $x_tab_step;
     given ($MaxSteps) {
         when ( $_ < 100 ) { $x_tab_step = 10 }
         when ( $_ < 8000 ) {
             my $approx_steps = $_ / 6;
             $x_tab_step = 100 * int( $approx_steps / 100 );
         }
         when ( $_ < 50000 ) {
             my $approx_steps = $_ / 6;
             $x_tab_step = 1000 * int( $approx_steps / 1000 );
         }
         $x_tab_step = 10000;
     }

     ### x_tab_step: $x_tab_step

     my ( $left, $bottom ) = BarCoordinateToFigCoordinate(2, 0, 0, -1, 0);
     my $top = $bottom - $MAX_BAR_HEIGHT;     
     my ($right) = BarCoordinateToFigCoordinate(2, $SEQUENCE_COUNT - 1, $CLUSTER_COUNT - 1, 1.1, 0);

     my $height_per_codelet = $MAX_BAR_HEIGHT / $MaxSteps;

     for ( my $count = 0 ; $count <= $MaxSteps ; $count += $x_tab_step ) {
         my $label = $count;
         if ( $count % 1000 == 0 ) {
             $label = ( $count / 1000 ) . 'k';
         }
         DrawScaleLine(
             {
                 left => $left,
                 right => $right,
                 label  => $label,
                 y      => $bottom - $count * $height_per_codelet,
             }
         );
     }
 }

 sub DrawScaleLine {
     my ($opts_ref) = @_;
     my %opts_ref = %$opts_ref;
     my ( $left, $right, $label, $y ) = @opts_ref{qw(left right label y)};
     $Canvas->createLine( $left, $y, $right, $y, @{ SCALE_LINE_OPTIONS() } );
     $Canvas->createText(
         $left - 3, $y,
         -text   => $label,
         -anchor => 'e',
         @{ SCALE_TEXT_OPTIONS() }
     );
 }


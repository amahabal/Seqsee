use strict;
use Smart::Comments;
use List::Util;
use Carp;

use constant ANSWERS_FILE      => 'InputList3.answers';
use constant RESULTS_DIRECTORY => 'RealData';

use Config::Std;
read_config ANSWERS_FILE() => my %ExperimentConfig;

my %track_these_times
    = map { $_ => 1 } qw{time_to_understand time_to_understand_plus_first_entry};
my $display_what = $ARGV[0] || 'time_to_understand';

unless ( $track_these_times{$display_what} ) {
    die "Not tracking $display_what!\n\nOnly tracking: ", join( ', ', keys %track_these_times ),
        "\n";
}

my %Results;

# Format:
# Key: Seqeuence (say, 'Extend 1 2 3 4')
# Value: Hash: Key:    time_to_understand
#              Value:  Array of Understanding Times

%Results = ReadResults(RESULTS_DIRECTORY);
## Results: %Results

DisplayResults( \%Results );

sub ReadResults {
    my ($directory) = @_;
    my %results;
    for my $file (<$directory/*>) {
        read_config $file => my %results_for_file;
        while ( my ( $section, $content ) = each %results_for_file ) {
            next if ( not( $section =~ /^ extend \s* [\d\s-]+ $/x ) );
            my $extension = join( ', ', @{ $content->{next_terms_entered} } );
            for ( keys %track_these_times ) {
                $results{$section}{$extension}{$_} ||= [];
            }
            push(
                @{ $results{$section}{$extension}{time_to_understand} },
                $content->{time_to_understand}
            );
            push(
                @{ $results{$section}{$extension}{time_to_understand_plus_first_entry} },
                $content->{time_to_understand} + $content->{typing_times}[0]
            );
        }
    }
    return %results;
}

sub DisplayResults {
    my ($results_ref) = @_;
    while ( my ( $set, $values ) = each %ExperimentConfig ) {
        my $is_extend;
        next if $set eq '';

        my $type = $values->{Type};
        next unless $set =~ /extend/i;
        print "NEXT SET: [$type]\n";
        my @sequences_in_set = @{ $values->{seq} } or die "No sequences for set $set!";
        for my $sequence_and_ext (@sequences_in_set) {
            $sequence_and_ext =~ m/^\s* (.*?) \s* \| \s* (.*?) \s* $/x
                or confess "Extension missing for $sequence_and_ext";
            my ( $sequence, $ext ) = ( $1, $2 );
            my @ext = split( /\s+/, $ext );
            print "   SEQ: $sequence... ($ext)\n";
            if ( exists $results_ref->{"extend $sequence"} ) {
                my @total_times;
                my @correct_total_times;
                while ( my ( $extension, $times ) = each %{ $results_ref->{"extend $sequence"} } ) {
                    my @times = @{ $times->{$display_what} };
                    my $is_correct = IsExtensionCorrect( $extension, \@ext );
                    my $prefix
                        = ( $is_correct == -1 ) ? '???' : ( $is_correct == 1 ) ? '***' : 'xxx';

                    print "\t $prefix:$extension\n";
                    print "\t\t", join( ", ", map { sprintf( "%5.3f", $_ ) } @times ), "\n";
                    print "\t\t AVERAGE: ", List::Util::sum(@times) / scalar(@times), "\n";
                    push @total_times, @times;
                    push( @correct_total_times, @times ) if $is_correct == 1;
                }
                print "\t Average: ", List::Util::sum(@total_times) / scalar(@total_times), "\n";
                if (@correct_total_times) {
                    print "\t Avg. When Correct: ",
                        List::Util::sum(@correct_total_times) / scalar(@correct_total_times), "\n";
                }
                if ( scalar(@ext) and scalar(@total_times) ) {
                    print "\t % Correct Answers: ",
                        sprintf( "%5.3f",
                        100 * scalar(@correct_total_times) / scalar(@total_times) ),
                        "\n";
                }
            }
            else {
                print "\t\t--\n";
            }
        }
    }
}

sub IsExtensionCorrect {
    my ( $string, $correct ) = @_;
    my @given_extension = grep { $_ =~ /\d/ } split( /, /, $string );
    my @correct_extension = @$correct;
    return -1 unless @correct_extension;
    for ( 0 .. List::Util::min( scalar(@given_extension), scalar(@correct_extension) ) - 1 ) {
        return 0 unless $given_extension[$_] == $correct_extension[$_];
    }
    return 1;
}

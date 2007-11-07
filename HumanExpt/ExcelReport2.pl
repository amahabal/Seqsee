use strict;
use Config::Std;
use Carp;
use List::Util qw(sum);
use Smart::Comments;

use Experiment::Encounter;
use Experiment::Participant;
use Experiment::Sequence;
use Experiment::SequenceSet;
use Win32::Excel::Util;

use OLE;
use Win32::OLE::Const 'Microsoft.Excel';     # wd  constants
use Win32::OLE::Const 'Microsoft Office';    # mso constants

use constant ANSWERS_FILE      => 'InputList3.answers';
use constant RESULTS_DIRECTORY => 'RealData';
use constant OUTPUT_FILE       => 'Results2.xsl';

read_config ANSWERS_FILE() => my %ExperimentConfig;
my @SequenceSets = SetupSequences( \%ExperimentConfig );

# Format of @Results:
# Each entry is for a single Experiment::Participant.
my @Results = ReadResults(RESULTS_DIRECTORY);

sub ReadResults {
    my ($directory) = @_;
    my @results;
    for my $file (<$directory/*>) {    ### Reasing Results ===>              Done[%]
        read_config $file => my %data_for_file;
        my $participant = Experiment::Participant->new();
        while ( my ( $section, $content ) = each %data_for_file ) {
            next if ( not( $section =~ /^ extend \s* ([\d\s-]+) $/x ) );
            my $presented_terms_string = $1;
            $presented_terms_string =~ s#\s*$##;
            my @presented_terms = split( /\s+/, $presented_terms_string );
            my $sequence  = Experiment::Sequence->FetchGivenPresentedTerms( \@presented_terms );
            my $encounter = new Experiment::Encounter(
                {   participant            => $participant,
                    sequence               => $sequence,
                    presented_terms_string => $presented_terms_string,
                    presented_terms        => [ split( /\s+/, $presented_terms_string ) ],
                    extension_by_user      => $content->{next_terms_entered},
                    time_to_understand     => $content->{time_to_understand},
                    typing_times           => $content->{typing_times},
                }
            );
            $participant->add_extension_encounter($encounter);
        }
        push @results, $participant;
    }
    return @results;
}

sub SetupSequences {
    my ($expt_config_ref) = @_;
    my @Ret;
    while ( my ( $k, $v ) = each %$expt_config_ref ) { ### Reading Config ==>  Done[%]
        next unless $k =~ /^\s*Extend/;
        my $type = $v->{Type};
        my @sequences = map { m/^\s*(\S.*?)\s*\|/ or die "No | in seq $_"; $1 } @{ $v->{seq} };
        my @sequence_objects;
        for my $seq (@sequences) {
            my $key = "Sequence $seq";
            die "Did not find key >>$key<<" unless exists( $expt_config_ref->{$key} );
            my $extensions = $expt_config_ref->{$key}{ValidExtension};
            if ( !$extensions ) {
                $extensions = [];
            }
            elsif ( !( ref $extensions ) ) {
                $extensions = [$extensions];
            }
            my @terms = split( /\s+/, $seq );
            my @valid_extensions = map { [ split( /\s+/, $_ ) ] } map { trim($_) } @{$extensions};
            push @sequence_objects,
                Experiment::Sequence->FetchOrCreate(
                {   presented_terms       => \@terms,
                    acceptable_extensions => \@valid_extensions,
                }
                );
        }
        push @Ret, Experiment::SequenceSet->new( { sequences => \@sequence_objects } );
    }
    return @Ret;
}

sub trim {
    $_[0] =~ s#^\s*##;
    $_[0] =~ s#\s*$##;
    $_[0];
}


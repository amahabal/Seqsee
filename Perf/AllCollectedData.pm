package Perf::AllCollectedData;
use ModuleSets::Standard;
use ModuleSets::Seqsee;

# Each value if an ArrayRef, consisting of ResultOfTestRuns objects.
my %Seqsee_Data_of : ATTR(:name<seqsee_data>);
my %Human_Data_of : ATTR(:name<human_data>);
my %LTM_Data_of : ATTR(:name<ltm_data>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $Seqsee_Data_of{$id} = _ReadDataFromDirectory('Perf/data/Seqsee');
    $Human_Data_of{$id}  = _ReadDataFromDirectory('Perf/data/Human');
    $LTM_Data_of{$id}    = _ReadDataFromDirectory('Perf/data/LTM');
}

sub _ReadDataFromDirectory {
    my ($directory) = @_;
    my @ret;

    for my $filename (<$directory/*>) {
        my $text       = read_file($filename);
        my $result_set = Storable::thaw($text);

        $result_set->set_version(
            Perf::Version->new( { string => $result_set->get_version } ) );
        $result_set->set_feature_set(
            Perf::FeatureSet->new( { string => $result_set->get_features } ) );

        my $sequence = $result_set->get_terms;
        $sequence = Perf::TestSequence->new( { string => $sequence } );
        $result_set->set_terms($sequence);

        if ( $result_set->is_ltm_result() ) {
            if ( my $context_sequence = $result_set->get_context() ) {
                $result_set->set_context(
                    Perf::TestSequence->new( { string => $context_sequence } )
                );
            }
        }

        push @ret, $result_set;
    }

    return @ret;
}

sub _GetDataForSequence {
    my ( $self, $opts_ref ) = @_;
    my %opts = %$opts_ref;
    my ( $type, $sequence, $context, $min_version, $max_version,
        $exact_feature_set )
      = @opts{
        qw{type sequence context min_version max_version exact_feature_set }};
    my $id = ident $self;

    my $array_ref;
    given ($type) {
        when ('Seqsee') { $array_ref = $Seqsee_Data_of{$id} }
        when ('Human')  { $array_ref = $Human_Data_of{$id} }
        when ('LTM')    { $array_ref = $LTM_Data_of{$id} }
        default { confess "type $type unknown" };
    }

    my @ret;
    given ($type) {
        when ('LTM') {
            for my $result_set (@$array_ref) {
                next
                  unless $sequence->IsCompatibleWith( $result_set->get_terms );
                if ($context) {
                    next
                      unless $context->IsCompatibleWith(
                        $result_set->get_context );
                }
                push @ret, $result_set;
            }
        }
        default {
            for my $result_set (@$array_ref) {
                next
                  unless $sequence->IsCompatibleWith( $result_set->get_terms );
                push @ret, $result_set;
            }
        }
    }

    if ( defined $min_version ) {
        @ret = grep { $min_version <= $_->get_version } @ret;
    }

    if ( defined $max_version ) {
        @ret = grep { $max_version >= $_->get_version } @ret;
    }

    if ( defined $exact_feature_set ) {
        @ret = grep { $exact_feature_set eq $_->get_features } @ret;
    }

    return @ret;
}

1;

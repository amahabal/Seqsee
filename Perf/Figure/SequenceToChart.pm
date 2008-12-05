package Perf::Figure::SequenceToChart;
use ModuleSets::Standard;
use ModuleSets::Seqsee;
my %Label_of : ATTR(:name<label>);
my %Data_Indexed_By_Cluster_for : ATTR(:name<data_indexed_by_cluster>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $string = $opts_ref->{string} 
           // confess "Missing required argument 'string'";
    my $label = $opts_ref->{label} 
           // confess "Missing required argument 'label'";
    my $is_ltm_self_config = $opts_ref->{is_ltm_self_config} 
           // confess "Missing required argument 'is_ltm_self_config'";
    my $all_read_data = $opts_ref->{all_read_data} 
           // confess "Missing required argument 'all_read_data'";
    my $clusters = $opts_ref->{clusters} // Default;
    
    if (!$is_ltm_self_config) {
        confess "Need clusters" unless $clusters;
    }

    $Label_of{$id} = $label;
    if ($is_ltm_self_config) {

    } else {
        my %data_indexed_by_cluster;
        for my $cluster (@{$clusters}) {
            my @data_sets = $all_read_data->GetDataForSequenceAndCluster({sequence => $sequence, cluster => $cluster});
            my @collated_data = map { @{ $_->get_results}} @data_sets;
            $data_indexed_by_cluster{$cluster} = Perf::CollatedData->new({data => \@collated_data});
        }
        $Data_Indexed_By_Cluster_for{$id} = \%data_indexed_by_cluster;
    }
}


1;

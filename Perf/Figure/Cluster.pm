package Perf::Figure::Cluster;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Getopt::Long;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Std;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES


my %Source_of : ATTR(:name<source>);
my %Constraints_Ref_of : ATTR(:name<constraints_ref>);
my %Color_of : ATTR(:name<color>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $config = $opts_ref->{config}
      // confess "Missing required argument 'config'";
    my $figure_type = $opts_ref->{figure_type}
      // confess "Missing required argument 'figure_type'";

    my $source = $figure_type eq 'LTM_SELF_CONTEXT' ? 'LTM' : $config->{source} // 'Source';
    $Source_of{$id} = $source;
    my %Data_Constraints;
    my %config           = %{$config};

    $Data_Constraints{min_version} = Perf::Version->new({string => $config{min_version}}) if defined $config{min_version};
    $Data_Constraints{max_version} = Perf::Version->new({string => $config{max_version}}) if defined $config{max_version};
    $Data_Constraints{exact_feature_set} = Perf::FeatureSet->new({string => $config{exact_feature_set}}) if defined $config{exact_feature_set};

    if ($figure_type eq 'LTM_WITH_CONTEXT' and $source eq 'LTM') {
        $Data_Constraints{context} = $config{context} // confess "context needed for every cluster that has LTM as its source";
    }
    $Constraints_Ref_of{$id} = \%Data_Constraints;
    $Color_of{$id} = _GetColor($source);
}

sub _GetColor {
    my ($source) = @_;
    return '#FF0000' if $source eq 'Human';
    return '#00FF00' if $source eq 'LTM';
    return '#0000FF';
}

sub get_constraints {
    my ($self) = @_;
    my $id = ident $self;
    return %{$Constraints_Ref_of{$id}};
}
               
sub is_human {
    my ($self) = @_;
    my $id = ident $self;
    return ($Source_of{$id} eq 'Human') ? 1 : 0;
}
               
    
    


1;


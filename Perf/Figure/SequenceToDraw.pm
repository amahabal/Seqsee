package Perf::Figure::SequenceToDraw;
use ModuleSets::Standard;
use ModuleSets::Seqsee;

my %Sequence_With_Markup_of : ATTR(:name<sequence_with_markup>);
my %Distractors_of : ATTR(:name<distractors>);
my %Label_of : ATTR(:name<label>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $string = $opts_ref->{string}
      // confess "Missing required argument 'string'";
    my $config = $opts_ref->{config}
      // confess "Missing required argument 'config'";
    my $possible_label = $opts_ref->{possible_label} // "label";

    $Sequence_With_Markup_of{$id} = $string;
    $Label_of{$id} = $config->{label} || $possible_label;
    
    if (my $d = $config->{distractor}) {
        $Distractors_of{$id} = (ref $d) ? $d : [$d];
    }
    $Distractors_of{$id} //= [];
}

1;


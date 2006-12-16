package Tk::SStream2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

our $list;
our $UPDATABLE = 1;
Construct Tk::Widget 'SStream2';

my $NumericSort = sub {
    return $_[0] <=> $_[1];
};


sub Populate{
    my ( $self, $args ) = @_;
    my $tags_ref = delete $args->{-tags_provided};
    $self->SUPER::Populate( );

    $list = $self;
    my $column_specs = [[-text => 'Age', -comparecommand => $NumericSort,
                         -textwidth => 5, -background => 'red', -fg => 'white'],
                        [-text => 'Thought', -textwidth => 40],
                        [-text => 'Component', -textwidth => 40],
                        [-text => 'Strength', -textwidth => 8,
                             -comparecommand => $NumericSort]];


    my $mb = $self->MListbox(%$args, -bg => 'white', -columns => $column_specs)->pack(-side => 'top');
    $self->Delegates(DEFAULT => $mb);
    $mb->columnConfigure(0, -bg => 'red', -foreground => '#ff0000');
}

sub clear{
    $list->delete('0.0', 'end');
}

sub Update{
    $list->delete('0.0', 'end');
    my $counter = 0;
    for my $tht (@SStream::OlderThoughts) {
        $counter++;
        my $tht_as_text = $tht->as_text();
        my $fringe = $tht->get_stored_fringe();
        for my $fringe_component (@$fringe) {
            $list->insert('end', [$counter, $tht_as_text, @$fringe_component]);
        }
    }
}

1;




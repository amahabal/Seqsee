package Tk::SStream2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

my $list;
my $mb;
my $mb_no_fringe;

our $UPDATABLE = 1;
Construct Tk::Widget 'SStream2';

my $NumericSort = sub {
    return $_[0] <=> $_[1];
};


sub Populate{
    my ( $self, $args ) = @_;
    my $tags_ref = delete $args->{-tags_provided};
    $self->SUPER::Populate( );

    my $column_specs_for_no_fringe =
        [[-text => 'Age', -comparecommand => $NumericSort, -textwidth => 5],
         [-text => 'Thought', -textwidth => 40]];
    $mb_no_fringe = $self->MListbox(-height => 10, -bg => 'white', -columns => $column_specs_for_no_fringe)->pack(-side => 'top');
    my $column_specs = [[-text => 'Age', -comparecommand => $NumericSort,
                         -textwidth => 5, -background => 'red', -fg => 'white'],
                        [-text => 'Thought', -textwidth => 40],
                        [-text => 'Component', -textwidth => 40],
                        [-text => 'Strength', -textwidth => 8,
                             -comparecommand => $NumericSort]];

    $list = $self;
    $mb = $self->MListbox(%$args, -bg => 'white', -columns => $column_specs)->pack(-side => 'top');
    # $self->Delegates(DEFAULT => $mb);
    $mb->columnConfigure(0, -bg => 'red', -foreground => '#ff0000');
}

sub clear{
    $mb->delete('0.0', 'end');
    $mb_no_fringe->delete('0.0', 'end');
}

sub Update{
    $mb->delete('0.0', 'end');
    $mb_no_fringe->delete('0.0', 'end');
    my $counter = 0;
    for my $tht (@SStream::OlderThoughts) {
        $counter++;
        my $tht_as_text = $tht->as_text();
        my $fringe = $tht->get_stored_fringe();
        if (@$fringe) {
            for my $fringe_component (@$fringe) {
                my ($component, $activation) = @$fringe_component;
                $component = $component->as_text() 
                    if UNIVERSAL::can($component, 'as_text');
                $mb->insert('end', [$counter, $tht_as_text, $component, $activation]);
            }
        } else {
            $mb_no_fringe->insert('end', [ $counter, $tht_as_text]);
        }
    }
}

1;




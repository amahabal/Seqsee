package Tk::SActivation2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

our $UPDATABLE = 'OnRaise';
our $LAST_UPDATE = -1;
Construct Tk::Widget 'SActivation2';

our $list;

sub Populate{
    my ( $self, $args ) = @_;
    $self->SUPER::Populate();

    my $column_specs = 
        [[-text => 'Concept', -textwidth => 40],
         [-text => 'Activation', -textwidth => 10],
             ];
    $list = $self->MListbox(-height => 30, -columns => $column_specs)
        ->pack(-side => 'top');

}

sub Update{
    $list->delete('0.0', 'end');
  my @concepts_with_activation = SLTM::GetTopConcepts(10);
  for (@concepts_with_activation) {
      my ($concept, $activation) = @{$_};
      $activation = sprintf('%6.4f', $activation);
      $list->insert('end', [$concept->as_text(), $activation]);
  }
}

1;

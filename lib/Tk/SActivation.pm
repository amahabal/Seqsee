package Tk::SActivation;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;

Construct Tk::Widget 'SActivation';

sub Populate{
  my ( $self, $args ) = @_;
  my $tags_ref = delete $args->{-tags_provided};
  $list = $self;
  $self->SUPER::Populate( $args );
  for (@$tags_ref) {
      $self->tagConfigure(@$_);
  }

  $self->tagBind('clickable', 
                 '<1>' => sub {
                     my $self = shift;
                     my @names = $self->tagNames('current');
                     # print join(", ", @names), "\n";
                     my ($name) = grep { m/^S/ } @names;
                     # print "You clicked", $name, "\n";
                     $vivify{$name}->display_self($SGUI::Info);
                 });


}


sub clear{
  $list->delete('0.0', 'end');
}

sub Update{
  $list->delete('0.0', 'end');
  my @concepts_with_activation = SLTM::GetTopConcepts(10);
  for (@concepts_with_activation) {
      my ($concept, $activation) = @{$_};
      $activation = sprintf('%6.4f', $activation);
      my $type = ref($concept);
      my $string = join('', $activation, '  ', $concept->as_text());
      $list->insert('end', $string, [$type]);
      $list->insert('end', "\n");
  }

}
 

1;

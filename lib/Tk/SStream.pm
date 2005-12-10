package Tk::SStream;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;
our %Tht2ID;
our %vivify;

Construct Tk::Widget 'SStream';

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
  %Tht2ID = ();
  %vivify = ();

  # Current Thought
  if ($SStream::CurrentThought) {
      $list->insert('end', 'Current Thought: ', [qw{heading}], 
                    "\n\t",       [],
                    $SStream::CurrentThought->as_text(), 
                    ['clickable', $vivify{$SStream::CurrentThought} =
                         $SStream::CurrentThought
                         ],
                           "\n\n",
                        );
  } else {
      $list->insert('end', '', [qw{heading}], "\n\n\n");
  }

  my $counter = 0;
  for my $tht (@SStream::OlderThoughts) {
      $counter++;
      $Tht2ID{$tht} = $counter;
      $list->insert('end',
                    "\t",     [],
                    $tht->as_text(), 
                    ["details", "clickable",$vivify{$tht} = $tht],
                    "\n",
                        );
  }

}


1;

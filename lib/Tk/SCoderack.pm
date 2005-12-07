package Tk::Coderack;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;

Construct Tk::Widget 'SCoderack';

sub Populate{
  my ( $self, $args ) = @_;
  my $tags_ref = delete $args->{-tags_provided};
  $list = $self;
  $self->SUPER::Populate( $args );
  for (@$tags_ref) {
      $self->tagConfigure(@$_);
  }
}

sub clear{
  $list->delete('0.0', 'end');
}

sub Update{
  $list->delete('0.0', 'end');

  # Forced Thought:
  if ($SCoderack::FORCED_THOUGHT) {
      $list->insert('end', 'Forced: ', [qw{heading}], 
                           "\n\t",       [],
                           $SCoderack::FORCED_THOUGHT->as_text(), [],
                           "\n\n",
                        );
  } else {
      $list->insert('end', '', [qw{heading}], "\n\n\n");
  }

  if ($SCoderack::SCHEDULED_THOUGHT) {
      $list->insert('end', 'Scheduled: ', [qw{heading}], 
                           "\n\t",       [],
                           $SCoderack::SCHEDULED_THOUGHT->as_text(), [],
                           "\n\n",
                        );
  } else {
      $list->insert('end', '', [qw{heading}], "\n\n\n");
  }

  my $counter = 0;
  for my $cl (@SCoderack::CODELETS) {
      $list->insert('end',
                    "\t",     [],
                    $cl->[0], "family",
                    "\t", [],
                    $cl->[1], "urgency",
                    "\n",
                        );
  }

}


1;

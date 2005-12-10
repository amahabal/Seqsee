package Tk::Coderack;
use Tk;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;
our %vivify;

Construct Tk::Widget 'SCoderack';

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
  %vivify = ();

  # Forced Thought:
  if ($SCoderack::FORCED_THOUGHT) {
      $list->insert('end', 'Forced: ', [qw{heading}], 
                    "\n\t",       [],
                    $SCoderack::FORCED_THOUGHT->as_text(), 
                    [$vivify{$SCoderack::FORCED_THOUGHT} =
                         $SCoderack::FORCED_THOUGHT, 
                     'clickable'],
                    "\n\n",
                        );
  } else {
      $list->insert('end', '', [qw{heading}], "\n\n\n");
  }

  if ($SCoderack::SCHEDULED_THOUGHT) {
      $list->insert('end', 'Scheduled: ', [qw{heading}], 
                           "\n\t",       [],
                    $SCoderack::SCHEDULED_THOUGHT->as_text(), 
                    [$vivify{$SCoderack::SCHEDULED_THOUGHT}=
                         $SCoderack::SCHEDULED_THOUGHT
                         , 'clickable'],
                           "\n\n",
                        );
  } else {
      $list->insert('end', '', [qw{heading}], "\n\n\n");
  }

  my $counter = 0;
  for my $cl (@SCoderack::CODELETS) {
      $vivify{$cl} = $cl;
      $list->insert('end',
                    "\t",     [],
                    $cl->[0], ["family", $cl, 'clickable'],
                    "\t", [],
                    $cl->[1], ["urgency", $cl, 'clickable'],
                    "\n",
                        );
  }

}


1;

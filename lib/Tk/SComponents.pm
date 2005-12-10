package Tk::SComponents;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

my $list;

Construct Tk::Widget 'SComponents';

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
                     $SStream::vivify{$name}->display_self($SGUI::Info);
                 });
}


sub clear{
  $list->delete('0.0', 'end');
}

sub Update{
  $list->delete('0.0', 'end');

  while (my($k, $v) = each %SStream::ComponentOwnership_of) {
      $list->insert('end',
                    $SStream::vivify{$k}->as_text, 
                    ["component", "clickable",$k],
                    "\n",
                        );
      while (my($k2, $v2) = each %$v) {
          $k2 = $Tk::SStream::Tht2ID{$k2};
          $list->insert('end',
                        "\t", "",
                        $v2, "strength",
                        "\t", "",
                        "Tht #$k2", "thought",
                        "\n",
                            );
      }
  }

}


1;

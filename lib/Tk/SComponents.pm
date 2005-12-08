package Tk::SComponents;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;

Construct Tk::Widget 'SComponents';

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

}


1;

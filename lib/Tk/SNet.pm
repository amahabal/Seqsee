package Tk::SNet;
use Tk::widgets qw{MListbox};
use base qw/Tk::Derived Tk::MListbox/;

our $list;
our @columns = ( [-text => "Node"],
		 [-text => "Activation", -textwidth => 10],
	       );

Construct Tk::Widget 'SNet';

sub ClassInit{
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ( $self, $args ) = @_;
  $list = $self;
  $args->{-moveable} = 0;
  $args->{-columns}  = \@columns;
  $self->SUPER::Populate( $args );
}

sub clear{
  $list->delete(0, 'end');
}

sub update{
  $list->delete(0, 'end');
  while (my ($name, $node) = each %SNet::Nodes) {
    $list->insert('end', [$name, "---"] );
  }
}

1;

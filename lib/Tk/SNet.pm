package Tk::SNet;
use Tk::widgets qw{Text};
use base qw/Tk::Derived Tk::Text/;

our $list;
Construct Tk::Widget 'SNet';

sub ClassInit{
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ( $self, $args ) = @_;
  $list = $self;
  $self->SUPER::Populate( $args );
  $self->tagBind('node', '<1>' => 
		 sub { 
		   my $line= $list->get('current linestart','current lineend');
		   $line =~ s/^\S+\s*//;
		   my $node = SNet->fetch($line);
		   #print "Need to deal with '$node'\n";
		   $node->display_details;
		 });
  $self;
}

sub clear{
  $list->delete('0.0', 'end');
}

sub redraw{
  $list->delete('0.0', 'end');
  while (my ($name, $node) = each %SNet::Nodes) {
    $list->insert('end', "---\t$name\n", 'node' );
  }
}



1;


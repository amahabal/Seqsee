package Tk::SInfo;

use Tk::widgets qw{Text};
use base qw/Tk::Derived Tk::Text/;

Construct Tk::Widget "SInfo";

our $head_style = [qw{-foreground blue -background #CCCCFF}];

sub ClassInit{
  my ( $class, $mw ) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ($self, $args) = @_;
  my $head_st = delete $args->{-head_style};
  $head_style = $head_st if (defined $head_st);
  $self->SUPER::Populate( $args );
  $self->init_tags;
}

sub init_tags{
  my $self = shift;
  $self->tag(qw{configure head}, @$head_style);
}

sub head{
  my ($self, $insert) = @_;
  $self->insert('end', "$insert\n", 'head');
}

sub body{
  my ($self, $line, $indent) = @_;
  $self->insert('end', "\t" x $indent, 'end', "$line\n");
}

sub hrule{
  my ($self, $indent) = @_;
  $self->insert('end', "\t" x $indent, 'end', "-------------\n");
}

sub skip{
  my ($self, $indent) = @_;
  $self->insert('end', "\n" x $indent);
}


sub clear{
  shift->delete('0.0', 'end');
}

1;

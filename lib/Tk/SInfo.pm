package Tk::SInfo;

use Tk::widgets qw{Text};
use base qw/Tk::Derived Tk::Text/;
use SFlags;

Construct Tk::Widget "SInfo";

our $head_style = [qw{-foreground blue -background #CCCCFF
		      -font -adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4
		    }];

our $head2_style = [qw{ -foreground red
			-font -adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4
		     }];

our $descflag_style = [qw{-foreground blue}];
our $desclabel_style = [qw{-foreground green}];
our $descdesc_style = [qw{-foreground red}];
our $bdescflag_style = [qw{-foreground blue -background #FF9999}];
our $hist_critical_style = [qw{-foreground red}];

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
  $self->tag(qw{configure head2}, @$head2_style);
  $self->tag(qw{configure descflag}, @$descflag_style);
  $self->tag(qw{configure desclabel}, @$desclabel_style);
  $self->tag(qw{configure descdesc }, @$descdesc_style);
  $self->tag(qw{configure bdescflag}, @$bdescflag_style);
  $self->tag(qw{configure hist_critical}, @$hist_critical_style);
}

sub head{
  my ($self, $insert) = @_;
  $self->insert('end', "$insert\n", 'head');
}

sub head2{
  my ($self, $insert) = @_;
  $self->insert('end', "   $insert\n", 'head2');
}

sub body{
  my ($self, $indent, $line) = @_;
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

sub description{
  my $self = shift;
  my ($desc, $depth) = @_;
  $self->insert('end', "\t" x $depth);
  $self->insert('end', "$desc->{flag}{str} ", 'descflag');
  $self->insert('end', join(", ", @{ $desc->{label} }), 'desclabel');
  $self->insert('end', " $desc->{descriptor}{str}\n", 'descdesc');
  for (@{$desc->{descs}}) {
    $self->description($_, $depth + 1);
  }
}

sub bdescription{
  my $self = shift;
  my ($desc, $depth) = @_;
  if ($desc->{bflag} eq $Bflag::both) {
    $self->insert('end', "\t" x $depth);
    $self->insert('end', "Both", 'bdescflag');
    $self->insert('end', " $desc->{flag}{pl_str} ", 'descflag');
    $self->insert('end', join(", ", @{ $desc->{label} }), 'desclabel');
    $self->insert('end', " $desc->{descriptor}{str}\n", 'descdesc');
    for (@{$desc->{descs}}) {
      $self->description($_, $depth + 1);
    }
  } else {
    $self->insert('end', "\t" x $depth);
    $self->insert('end', "Change ($desc->{descriptor}[2])", 'bdescflag');
    $self->insert('end', "(" );

    $self->insert('end', "$desc->{flag}[0]{str} ", 'descflag');
    $self->insert('end', join(", ", @{ $desc->{label}[0] }), 'desclabel');
    $self->insert('end', " $desc->{descriptor}[0]{str}", 'descdesc');

    $self->insert('end', ") ===> (" );

    $self->insert('end', "$desc->{flag}[1]{str} ", 'descflag');
    $self->insert('end', join(", ", @{ $desc->{label}[1] }), 'desclabel');
    $self->insert('end', " $desc->{descriptor}[1]{str}", 'descdesc');

    $self->insert('end', ")\n");
  }
}

sub bond{
  my ($self, $bond, $depth) = @_;
  $self->insert('end', "\t" x $depth);
  $self->insert('end', $bond->{str});
  $self->insert('end', "\n");
}

sub history{
  my ($self, $object) = @_;
  $self->head2("History");
  foreach (@{ $object->{history} }) {
    if ($_->[2]) {
      $self->insert('end', "\t$_->[0]\t$_->[3]\n\t  $_->[1]\n", 'hist_critical');
    } else {
      $self->insert('end', "\t$_->[0]\t$_->[3]\n\t  $_->[1]\n");
    }
  }
}

1;

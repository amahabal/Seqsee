package SMCat;
use strict;

our %MCats;

sub new{
  my $package = shift;
  my %args = @_;
  my $name = $args{name} || die "Must provide a name for new SMCat()";
  my $self = bless { name => $name }, $package;

  $self;
}

sub register{
  my $self = shift;
  my $name = $self->{name};
  if (exists $MCats{$name}) {
    die "Another MCat of this name already registered!" 
      unless $MCats{$name} eq $self;
  }
  $MCats{$name} = $self;
}

1;

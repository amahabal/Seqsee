package SNode;
use strict;
use SDescs;

our @ISA = qw{SDescs};

our %Str2Name;

sub new{
  my $package = shift;
  my $name    = shift;
  my $self    =   bless { name  => $name, 
			  str   => "{$name}",
			  descs => [],
			}, $package;
  $Str2Name{$self} = $name;
  $self;
}

sub halo{
  my $self = shift;
  # XXX Currently I can just pretend to use all the links...
  #     But that'll change, as I understand what is needed better
  return $self->descriptors;
}

sub relation{
  my ($self, $other_node) = @_;
  foreach my $link (@{ $self->{descs} }) {
    next unless ($link->{descriptor} eq $other_node and 
		 $link->{flag} eq $Dflag::has
		);
    return $link->{label}[0];
  }
  return undef;
}

1;

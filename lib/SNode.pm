package SNode;
use strict;
use SDescs;

use SNodeType::Number; # wrong place!

our %DanglingLinks;

our @ISA = qw{SDescs SFascination};

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

sub init{
  my $self = shift;
  $self->{descs} = [];
  $self->{str}   = "{$self->{shortname}}";
  $self;
}

sub establish_links{
  my $self = shift;
  my @links = $self->find_links;
  for my $link (@links) {
    $link->hardcode_ref;
    unless (ref $link->{descriptor}) {
      # So the target does not exist! remember this fact...
      push(@{ $DanglingLinks{ $link->{descriptor} } }, $link);
    }
    $self->add_desc($link);
  }
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

sub hardcode_desc_refs{
  my $self = shift;
  for (@{$self->{descs}}) { $_->hardcode_ref; }
}

1;

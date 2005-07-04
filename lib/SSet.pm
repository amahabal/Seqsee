package SSet;
use strict;
use Class::Std;

my %members_of :ATTR;

sub insert{
  my $self = shift;
  my $ref = ($members_of{ident $self} ||= {});
  for (@_) {
    $ref->{$_} = $_;
  }
  return $self;
}

sub members{
  my $self = shift;
  return values %{ $members_of{ident $self} };
}

sub is_member{
  my ( $self, $what ) = @_;
  return 1 if exists $members_of{ident $self}{$what};
  return;
}

*has = *is_member;

1;

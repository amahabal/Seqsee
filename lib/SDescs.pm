package SDescs;
use strict;

sub add_desc{
  my $self = shift;
  my $desc = shift;
  my $descstr = $desc->{str};
  for my $self_d ( @{ $self->{descs} } ) {
    if ($self_d->{str} eq $descstr) {
      foreach (@{ $desc->{descs} }) {
	$self_d->add_desc($_);
      }
      return;
    }
  }
  # This is totally new!
  push(@{ $self->{descs} }, $desc);
}

1;

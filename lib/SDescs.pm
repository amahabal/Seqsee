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

sub descriptors{
  my $self = shift;
  map { $_->{descriptor} } @{ $self->{descs} };
}

sub get_description{
  my ($self, $descriptor) = @_;
  grep { $_->{descriptor} eq $descriptor } @{ $self->{descs} };
}

sub compare{
  my ($obj1, $descriptor1, $obj2, $descriptor2) = @_;
  my @descriptions1 = $obj1->get_description($descriptor1);
  my @descriptions2 = $obj2->get_description($descriptor2);
  my $bdesc;
  LOOP: for my $d1 (@descriptions1) {
    for my $d2 (@descriptions2) {
      $bdesc = $d1->compare($d2);
      last LOOP if $bdesc;
    }
  }
  return $bdesc;
}

1;

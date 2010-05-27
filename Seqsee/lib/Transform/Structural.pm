package Mapping::Structural;
sub create {
  my ( $package, $opts_ref ) = @_;
  Seqsee::Mapping::Structural->create($opts_ref);
}

sub new {
  my $package = shift;
  Seqsee::Mapping::Structural->new(@_);
}

1;

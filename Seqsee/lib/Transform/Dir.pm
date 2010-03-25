package Transform::Dir;
sub create {
  my ( $package, $opts_ref ) = @_;
  Seqsee::Mapping::Dir->create($opts_ref);
}

sub new {
  my $package = shift;
  Seqsee::Mapping::Dir->new(@_);
}

1;

package Transform::Position;
sub create {
  my ( $package, $opts_ref ) = @_;
  Seqsee::Mapping::Position->create($opts_ref);
}

sub new {
  my $package = shift;
  Seqsee::Mapping::Position->new(@_);
}

1;

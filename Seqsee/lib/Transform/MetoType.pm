package Transform::MetoType;
sub create {
  my ( $package, $opts_ref ) = @_;
  Seqsee::Mapping::MetoType->create($opts_ref);
}

sub new {
  my $package = shift;
  Seqsee::Mapping::MetoType->new(@_);
}

1;

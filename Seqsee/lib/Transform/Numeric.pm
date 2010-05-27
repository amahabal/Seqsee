package Mapping::Numeric;
sub create {
  my ( $package, $opts_ref ) = @_;
  Seqsee::Mapping::Numeric->create($opts_ref);
}

sub new {
  my $package = shift;
  Seqsee::Mapping::Numeric->new(@_);
}

1;

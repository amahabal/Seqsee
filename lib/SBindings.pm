package SBindings;
use strict;
use Carp;
use Class::Std;
use SBindings::Blemish;

my %values_of_of :ATTR( :get<values_of> );
my %blemishes_of :ATTR( :get<blemishes> );

sub BUILD{
  my ( $self, $id, $opts ) = @_;
  $blemishes_of{$id} = [];
}
sub add_blemish{
  my ( $self, $blemish ) = @_;
  UNIVERSAL::isa($blemish, "SBindings::Blemish")
      or croak "Need SBindings::Blemish";
  push (@{ $blemishes_of{ident $self} }, $blemish);
}

sub set_value_of{
  my ( $self, $what_ref ) = @_;
  my $val_ref = ($values_of_of{ident $self} ||= {});
  while (my ($k, $v) = each %$what_ref) {
    $val_ref->{$k} = $v;
  }
}

1;

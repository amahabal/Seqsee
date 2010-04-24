package ResultOfPlonk;
use strict;
use Class::Std;
use ResultOfAttributeCopy;

my %ObjectBeingPlonked_of : ATTR(:get<object_being_plonked>);
my %ResultantObject_of : ATTR(:get<resultant_object>);
my %AttributeCopyResult_of : ATTR(:get<attribute_copy_result>);

sub BUILD {
  my ( $self, $id, $opts_ref ) = @_;
  exists( $opts_ref->{resultant_object} ) or die;
  $ResultantObject_of{$id}     = $opts_ref->{resultant_object};
  $ObjectBeingPlonked_of{$id}  = $opts_ref->{object_being_plonked} or die;
  $AttributeCopyResult_of{$id} = $opts_ref->{attribute_copy_result} or die;
}

sub Failed {
  my ( $package, $object_being_plonked ) = @_;
  return $package->new(
    {
      object_being_plonked  => $object_being_plonked,
      resultant_object      => undef,
      attribute_copy_result => ResultOfAttributeCopy->Failed(),
    }
  );
}

sub PlonkWasSuccessful {
  my ($self) = @_;
  my $id = ident $self;
  return ( defined $ResultantObject_of{$id} ) ? 1 :0;
}

sub AttributeCopyWasSuccessful {
  my ($self) = @_;
  my $id = ident $self;
  return $AttributeCopyResult_of{$id}->WasSuccessful();
}

1;


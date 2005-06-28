package SPos::Global;
use base 'SPos';

sub new{
  my ( $package, %opts ) = @_;
  my $finder = delete $opts{finder};
  UNIVERSAL::isa( $finder, "SPosFinder") or die "need sposfinder";
  my $self = bless {}, $package;
  $self->{finder} = $finder;
  $self;
}

sub find_range{
  my ( $self, $built_obj ) = @_;
  $self->{finder}->find_range($built_obj);
}

1;

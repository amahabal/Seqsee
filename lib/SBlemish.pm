package SBlemish;
use Perl6::Attributes;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  $self;
}

sub blemish{
  my $self = shift;
  return $.blemisher->($self, @_);
}

sub unblemish{
  my $self = shift;
  return $.unblemisher->($self, @_);
}

sub is_blemished{
  my $self = shift;
  my $obj  = shift;
  $.instancer->($self, $obj);
}

1;

package SPos;
use Carp;
use Moose;
use overload ('eq' => '__equality__',
              '~~' => '__equality__',
              fallback => 1);

has position => (
    is         => 'rw',
    isa        => 'Int',
    required   => 1,
);

sub BUILD {
  my $self = shift;
  if ($self->position <= 0) {
    confess "Attempt to set position to " . $self->position;
  }
}

sub BUILDARGS {
  my $class = shift;
  if (@_ == 1 and not(ref($_[0]))) {
    return { position => $_[0] }
  }
  return {@_};
}

sub __equality__ {
  $_[0]->position() == $_[1]->position();
}

1;

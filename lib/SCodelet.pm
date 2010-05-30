package SCodelet;
use 5.010;
use Moose;
use English qw( -no_match_vars );
use Smart::Comments;

extends 'SCodeletBase';

has creation_time => (
  is       => 'ro',
  required => 1,
);

sub BUILDARGS {
  my ( $package, $family, $urgency, $args_ref ) = @_;
  $args_ref ||= {};
  return {
    family        => $family,
    urgency       => $urgency,
    creation_time => $Global::Steps_Finished,
    arguments     => $args_ref
  };
}

use overload (
  '@{}' => sub {
    my ($self) = @_;
    return [
      $self->family(),        $self->urgency(),
      $self->creation_time(), $self->arguments()
    ];
  },
  fallback => 1
);

sub as_text {
  my ($self) = @_;
  return
    "Codelet(family="
  . $self->family()
  . ",urgency="
  . $self->urgency()
  . ",args="
  . SUtil::StringifyForCarp( $self->arguments() );
}

sub schedule {
  my ($self) = @_;
  SCoderack->add_codelet($self);
}

__PACKAGE__->meta->make_immutable;
1;

1;

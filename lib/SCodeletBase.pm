package SCodeletBase;
use 5.010;
use Moose;
use English qw( -no_match_vars );
use Smart::Comments;

has family => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has urgency => (
  is       => 'ro',
  required => 1,
);

has arguments => (
  is       => 'ro',
  required => 1,
);

sub run {
  my $self = shift;

  if ($Global::debugMAX) {
    main::message(
      [
        $self->family, 'green',
        "About to run: " . SUtil::StringifyForCarp($self)
      ]
    );
  }

  return
  unless CheckFreshness( $self->creation_time, values %{ $self->arguments } );

  $Global::CurrentCodelet       = $self;
  $Global::CurrentCodeletFamily = $self->family;

  no strict;
  my $method_name = "SCF::" . $self->family() . '::run';
  $method_name->( $self, $self->arguments );
}

sub CheckFreshness {
  my $since = shift;    # Should not have changed since this time.
  for (@_) {
    return unless ( IsFresh( $_, $since ) );
  }
  return 1;
}

use Class::Multimethods;
multimethod IsFresh => ( '*', '#' ) => sub {

  # detualt case:fresh.
  return 1;
};

multimethod IsFresh => ( 'HASH', '#' ) => sub {
  return 1;
};

multimethod IsFresh => ( 'SAnchored', '#' ) => sub {
  my ( $obj, $since ) = @_;
  return $obj->UnchangedSince($since);
};
multimethod IsFresh => ( 'SRelation', '#' ) => sub {
  my ( $rel, $since ) = @_;
  my @ends = $rel->get_ends();
  return ( $ends[0]->UnchangedSince($since)
    and $ends[1]->UnchangedSince($since) );
};

__PACKAGE__->meta->make_immutable;
1;

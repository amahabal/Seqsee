package SThought;
use 5.10.0;
use strict;

use Moose;
use Carp;
use Memoize;
memoize('create');

has stored_fringe => ( is => 'rw', );

has core => (
  is       => 'rw',
  required => 1,
  weak_ref => 1,
);

# method: create
# creates a though given the core
#
sub create {
  my ( $package, $core ) = @_;
  state $_Type2Class = {
    qw(   SElement        SThought::SElement
    SAnchored       SThought::SAnchored
    SRelation       SThought::SRelation
    )
  };

  my $class;
  if ( $core->isa('SCat::OfObj') ) {
    $class = 'SThought::SCat';
  }
  else {
    $class = $_Type2Class->{ ref $core }
    // confess "Don't know how to think about $core";
  }

  return $class->new( { core => $core } );
}

# method: schedule
# schedules self as a scheduled thought
#
#    Parallels a method in SCodelet that adds itself to the coderack.
sub schedule {
  my ($self) = @_;
  SCoderack->schedule_thought($self);
}

# method: force_to_be_next_runnable
#
#
sub force_to_be_next_runnable {
  my ($self) = @_;
  SCoderack->force_thought($self);
}

sub display_self {
  my ( $self, $widget ) = @_;
  $widget->Display( "Thought", ["heading"], "\n", $self->as_text );
}

1;


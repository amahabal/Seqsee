package SCodelet;
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

has creation_time => (
  is       => 'ro',
  required => 1,
);

has arguments => (
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
  my $code = *{ "SCF::" . $self->family . "::run" }{CODE}
  or fishy_codefamily( $self->family );
  eval { $code->( $self, $self->arguments ) };
  if ($EVAL_ERROR) {
    die $EVAL_ERROR if ref($EVAL_ERROR);
    if ( $EVAL_ERROR =~ /_TK_EXIT_/ ) {
      die $EVAL_ERROR;
    }
    if ( $EVAL_ERROR =~ /\n=====\n/ ) {

      # Probably already a confess..
      die("Encountered a confess while running a codelet:\n$EVAL_ERROR");
    }
    else {
      confess( "Encountered C<die> while running a codelet. Family => "
        . $self->family
        . " \n $EVAL_ERROR" );
    }
  }
}

sub fishy_codefamily {
  my $family = shift;
  print "fishy_codefamily called: $family!\n";
  unless ( exists $INC{"SCF/$family.pm"} ) {
    SErr::Code->throw(
      "The codefamily $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?"
    );
  }
  SErr::Code->throw("COuld not find codeobject for family $family. Problem?");
}

# method: schedule
# adds self to Coderack
#
#    Parallels a method in SThought that schedules itself.
sub schedule {
  my ($self) = @_;
  SCoderack->add_codelet($self);
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

1;

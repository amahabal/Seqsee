package SBlemish;
use SCat;
use strict;

#use Smart::Comments;
use Set::Scalar;
our @ISA = qw{SCat};

use Class::Std;

my %empty_what_of :ATTR( :init_arg<empty_what> :set<empty_what> );
my %guesser_flat_of_of :ATTR(:init_arg<guesser_flat_of> :set<guesser_flat_of> );
my %instancer_deep_of :ATTR;
my %instancer_flat_of :ATTR( :get<instancer_flat> );

sub BUILD {
  my ( $self, $id, $opts ) = @_;
  $self->get_att()->insert("what");

  $self->compose;

  $self->set_blemished(1);
  $instancer_flat_of{$id} =
    $self->generate_instancer_flat( $opts->{guesser_flat_of} );
  $instancer_deep_of{$id} = $self->get_instancer;
  $self->set_instancer(
    sub {
      my $self = shift;
      my $id   = ident $self;

      #print "In instancer\n";
      if ( not(@_) or ( @_ == 1 and $_[0]->is_empty ) ) {
        return $empty_what_of{$id} if $self->get_empty_ok();
        return undef;
      }
      my $bindings;
      if ( @_ == 1 ) {

        #print "\tSingle object, only a deep check($_[0])\n";
        $bindings = $instancer_deep_of{$id}->( $self, $_[0] );

        #print "In blemished instancer: got $bindings\n";
        #print "\$bindings->{what}: $bindings->{what}\n";
        return $bindings if $bindings;
      }
      else {

        #print "\tSeveral objects, only a shallow check\n";
        $bindings = $instancer_flat_of{$id}->( $self, @_ );
        return $bindings;
      }
    }
  );
}

sub blemish {
  my ( $self, $object ) = @_;
  my $ret = $self->build( { what => $object } )
    or return;
  ### $ret
  $ret->add_cat( $self, { what => $object } );
  $ret;
}

sub generate_instancer_flat {
  my ( $self, $guesser_hash ) = @_;
  ### $guesser_hash
  my $id   = ident $self;
  my @atts = $self->get_att()->members;
  foreach (@atts) {
    $guesser_hash->{$_}
      or die "cannot generate flat instancer; do not know how to guess $_";
  }
  return sub {
    my ( $me, @objects ) = @_;

    # print "#\tIn flat instancer...args: @objects\n";
    my %guess;
    for (@atts) {

      #print "#\t\tguessing '$_'\n";
      my $guess = $guesser_hash->{$_}->( $me, @objects );

      #print "#\t\t    guessed $guess\n";
      return undef unless defined $guess;
      $guess{$_} = $guess;

      #$guess->show;
    }
    my $guess_built = $me->build( {%guess} );

#$guess_built->show;
#print "\t\t guess built: $guess_built. Flattens to: ", $guess_built->flatten(), "\n";
#print "\t\tOriginal objects flatten to: ", map { $_->flatten } @objects;
#print "\n";
    if ( $guess_built->semiflattens_ok(@objects) ) {
      return \%guess;
    }
    else {
      return undef;
    }
  };
}

sub unblemish {
  my ( $self, $object ) = @_;
  my $bindings = $self->is_instance($object) or return undef;
  $bindings->{what};
}

sub is_blemished {
  my $self = shift;
  my $obj  = shift;
  $self->is_instance($obj);
}

1;

package SBlemish;
use SCat;
use strict;
use Carp;

#use Smart::Comments;
our @ISA = qw{SCat};

use Class::Std;

my %empty_what_of :ATTR( :set<empty_what> );
my %guesser_flat_of_of :ATTR(:set<guesser_flat_of> );
my %instancer_deep_of :ATTR;
my %instancer_flat_of :ATTR( :get<instancer_flat> );

sub BUILD {
  my ( $self, $id, $opts ) = @_;
  $self->get_att()->insert("what");

  $self->compose;
  
  $empty_what_of{$id}      = $opts->{empty_what_of};
  $guesser_flat_of_of{$id} = $opts->{guesser_flat_of};

  $self->set_blemished(1);
  $instancer_flat_of{$id} =
    $self->generate_instancer_flat( $opts->{guesser_flat_of} );
}

sub blemish {
  my ( $self, $object ) = @_;
  my $ret = $self->build( { what => $object } )
    or return;
  ### $ret
  $ret->add_cat( $self, { what => $object } );
  $ret;
}

sub is_instance_flat{
  my ( $self, @objects ) = @_;
  $instancer_flat_of{ident $self}->($self, @objects);
}

sub generate_instancer_flat {
  my ( $self, $guesser_hash ) = @_;
  ### $guesser_hash
  my $id   = ident $self;
  my @atts = $self->get_att()->members;
  foreach (@atts) {
    $guesser_hash->{$_}
      or croak "cannot generate flat instancer; do not know how to guess $_";
  }
  return sub {
    my ( $me, @objects ) = @_;

    #print "#\tIn flat instancer...args: @objects\n";
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

    if ( $guess_built->semiflattens_ok(@objects) ) {
      return { value => \%guess };
    }
    else {
      return undef;
    }
  };
}

sub unblemish {
  my ( $self, $object ) = @_;
  my $bindings = $self->is_instance($object) or return undef;
  $bindings->get_values_of()->{what};
}

sub is_blemished {
  my $self = shift;
  my $obj  = shift;
  $self->is_instance($obj);
}

1;

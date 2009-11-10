#####################################################
#
#    Package: Result0fCanBeSeenAs
#
#####################################################
#####################################################

package ResultOfCanBeSeenAs;
use strict;
use Carp;
use Class::Std;
use base qw{};

our %success_of : ATTR;
our %entire_blemish_of : ATTR;
our %part_blemish_of : ATTR;

use overload (
  q{bool} => sub {
    my ($self) = @_;

    # print "Checking booleanness...\n";
    return $success_of{ ident $self};
  },
  fallback => 1,

);

sub BUILD {
  my ( $self, $id, $opts_ref ) = @_;
  $success_of{$id}        = $opts_ref->{success};
  $entire_blemish_of{$id} = $opts_ref->{entire};
  $part_blemish_of{$id}   = $opts_ref->{part};
}

sub IsEntireBlemished {
  my ($self) = @_;
  $entire_blemish_of{ ident $self};
}

*GetEntireBlemish = *IsEntireBlemished;

sub ArePartsBlemished {
  my ($self) = @_;
  $part_blemish_of{ ident $self};
}

*GetPartsBlemished = *ArePartsBlemished;

sub IsBlemished {
  my ($self) = @_;
  my $id = ident $self;
  return ( $entire_blemish_of{$id} or $part_blemish_of{$id} );
}

sub newUnblemished {
  my ($package) = @_;
  return $package->new( { success => 1 } );
}

sub newEntireBlemish {
  my ( $package, $meto ) = @_;
  return $package->new( { success => 1, entire => $meto } );
}

sub newByPart {
  my ( $package, $blemish_hash ) = @_;
  return $package->new( { success => 1, part => $blemish_hash } );
}

{
  my $NO = ResultOfCanBeSeenAs->new( { success => 0 } );

  sub NO() {
    return $NO;
  }

}
1;

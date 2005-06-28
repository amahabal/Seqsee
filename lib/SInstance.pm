package SInstance;
use strict;
use SCat;
use Carp;

use Class::Std;

my %cats_of_of :ATTR( :get<cats_hash> :set<cats_hash> );

sub BUILD {
  $cats_of_of{ $_[1] } = {};
}

sub add_cat {
  ( @_ == 3 ) or croak "add cat requires three args";
  my ( $self, $cat, $bindings ) = @_;
  UNIVERSAL::isa( $cat, "SCat" ) or croak "cat passed to add_cat ain't a cat";

  foreach ( keys %$bindings ) {
    $cat->has_attribute($_) or croak "$cat doesn't have attribute $_";
  }
  $SCat::Str2Cat{$cat} = $cat;
  $cats_of_of{ ident $self}{$cat} = $bindings;
  return $self;
}

sub get_cat_bindings {
  my ( $self, $cat ) = @_;
  return unless exists $cats_of_of{ ident $self}{$cat};
  return $cats_of_of{ ident $self}{$cat};
}

sub get_cats {
  my $self = shift;
  return map { $SCat::Str2Cat{$_} } keys %{ $cats_of_of{ ident $self} };
}

sub get_blemish_cats {
  my $self = shift;
  my %ret;
  while ( my ( $k, $binding ) = each %{ $cats_of_of{ ident $self} } ) {
    if ( $SCat::Str2Cat{$k}->is_blemished_cat ) {
      $ret{$k} = $binding->{what};
    }
  }
  return \%ret;
}

sub instance_of_cat {
  my ( $self, $cat ) = @_;
  UNIVERSAL::isa( $cat, "SCat" ) or die;
  return exists $cats_of_of{ ident $self}{$cat};
}

1;

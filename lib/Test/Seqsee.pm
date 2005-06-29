use strict;
use Test::More;
use Test::Exception;
use Test::Deep;

sub undef_ok {
  my ( $what, $msg ) = @_;
  if ( not( defined $what ) ) {
    $msg ||= "is undefined";
    ok( 1, $msg );
  }
  else {
    $msg ||= "expected undef, got $what";
    ok( 0, $msg );
  }
}

sub instance_of_cat_ok {
  my ( $what, $cat, $msg ) = @_;
  no warnings;
  $msg ||= "$what is an instance of $cat";
  ok( $what->instance_of_cat($cat), $msg );
}

sub SInt::structure_ok {
  my ( $self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub SBuiltObj::structure_ok {    # ONLY TO BE USED FROM TEST SCRIPTS
  my ( $self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub blemished_where_ok {
  my ( $bindings, $where_ref ) = @_;
  my @where = map { $_->{where} } @{$bindings->{blemishes}};
  cmp_deeply \@where, $where_ref, "Location of Blemished";
}

sub blemished_starred_okay {
  my ( $bindings, $star_ref ) = @_;
  my @starred = map { $_->{starred} } @{$bindings->{blemishes}};
  cmp_deeply \@starred, $star_ref, "Starred versions of Blemished";
}

sub blemished_real_okay {
  use Smart::Comments;
  my ( $bindings, $real_ref ) = @_;
  my @real = map { $_->{real} } @{$bindings->{blemishes}};
  my $msg = "Original (unstarred) versions of Blemished"; 
  if (@real == @$real_ref){
    for (my $i=0; $i < @real; $i++) {
      next if $real[$i]->structure_is($real_ref->[$i]);
      ok 0, $msg;
    }
    ok 1, $msg;
  } else {
    ok 0, $msg;
  }
}

1;

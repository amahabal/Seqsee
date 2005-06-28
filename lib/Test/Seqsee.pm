use strict;
use Test::More;
use Test::Exception;
use Test::Deep;

sub undef_ok{
  my ($what, $msg) = @_;
  if (not(defined $what)) {
    $msg ||= "is undefined";
    ok(1, $msg);
  } else {
    $msg ||= "expected undef, got $what";
    ok(0, $msg);
  }
}

sub instance_of_cat_ok{
  my ($what, $cat, $msg) = @_;
  no warnings;
  $msg ||= "$what is an instance of $cat";
  ok( $what->instance_of_cat($cat), $msg );
}

sub SInt::structure_ok{
  my ($self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok($self->structure_is($potential_struct), $msg);
}

sub SBuiltObj::structure_ok{ # ONLY TO BE USED FROM TEST SCRIPTS
  my ($self, $potential_struct, $msg ) = @_;
  $msg ||= "structure of $self";
  Test::More::ok($self->structure_is($potential_struct), $msg);
}




1;

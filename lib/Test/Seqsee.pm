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
  $msg ||= "$what is an instance of $cat($cat->{name})";
  ok( $what->instance_of_cat($cat), $msg );
}

1;

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

1;

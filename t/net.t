use Test::More qw{no_plan};
use Test::Exception;

use blib;

our @node_list = qw{1 2 3 4 5 6 7 8 9 10 succ pred};

BEGIN { use_ok("SNet")};

{
  our $none_missing_so_far = 1;
  for (@node_list) {
    unless ($ {"SNet::node_$_"}) {
      diag("Node $_ not defined!");
      $none_missing_so_far = 0;
      last;
    }
  }
  ok($none_missing_so_far);
}


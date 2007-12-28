use Benchmark qw(:all);

timethese 400, {
  with    => "system 'perl -Mwith_p6subs -e \"1+1\"'; 1",
  without => "system 'perl -Mwithout_p6subs -e \"1+1\"'; 1",
}

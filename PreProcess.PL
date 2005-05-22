use strict;
our %ModTimes;
for ("lib/SCodeConfig.pm", "GenCL.pl", "SCodeConfig.txt") {
  $ModTimes{$_} = (-M $_) || 10000;
  # print "Mod time: ", -M $_, "\n";
}

if ($ModTimes{"lib/SCodeConfig.pm"} > $ModTimes{"GenCL.pl"} or
    $ModTimes{"lib/SCodeConfig.pm"} > $ModTimes{"SCodeConfig.txt"}) {
  system "perl GenCL.pl; perl GenCL.pl --info --list > SCodeConfig.list; perl Makefile.PL; make";
}

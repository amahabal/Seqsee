role SHistory;

has @.history;

method add_history(String $msg, Bool ?$critical = false){
  my $date   = $*CurrentEpoch;
  my $family = $*CurrentCodelet.family;
  @.history.unshift([$date, $msg, $critical, $family]);
}

method last_critical_change_time() returns Int{
  for @.history {
    return $_.[0] if $_.[2];
  }
  return 0;
}

method is_outdated() returns Bool{
  $_.last_critical_change_time > $*CurrentCodelet.eob;
}

1;

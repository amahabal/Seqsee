class Slink;

has SNode $.from;
has SNode $.to;
has Bool  %:_labels is shape(SNode);


method establish_link(+$from, +$to, *@labels){
  die "establish_link called with a missing from or to"
    unless (defined $from and defined $to);
  if my $link = $from.get_link_to($to) {
    for @labels -> $label {
       %link._labels.{$label} = 1 unless %link._labels.{$label};
       # That is possibly wrong. I am just saying that labels are a set. What about when you want to say "not near" instead of "near"? Maybe in those situations, the concept "not near" has to be explicitely manufactured.	
    }
  } else {
    my $link = new SLink(from => $from, to => $to) <== *@labels;
    $from.add_outgoing_link($to, $link);
    $to.add_incoming_link($from, $link);
  }
}

method labels(){
  return %._labels.values(); # Hmm.. that is not lazy!
}

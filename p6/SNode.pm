class SNode;

has String         $.name;
has Num            $.act;
has Num            $.act_buffer     = 0;
has Bool           $.clamped        = false;
has Int            $.depth;
has SLink          %.outlinks      is shape(SNode);
has SLink          %.inlinks       is shape(SNode);


method set_activation(Num $act){
  return if $.clamped;
  $.act        = $act;
  $.act_buffer = 0;
}

method increase_activation(Num $amt){
  return if $.clamped;
  $.act_buffer += $amt;
}

method flush_activation(){
  return if $.clamped;
  $.act += $.act_buffer;
  $.act = 100 if $.act > 100;
  $.act =   0 if $.act <   0;
  $.act_buffer = 0;
}

method add_outgoing_link($to, $link){
  %.outlinks{$to} = $link;
}

method add_incoming_link($from, $link){
  %.inlinks{$from} = $link;
}

method get_link_to($to){
  return %.outlinks{$to}; # for perl5, add "if exists()"
}

method get_link_from($from){
  return %.inlinks{$from}; # for perl5, add "if exists()"
}

method spread_activation($self:){
  for %.outlinks.kv -> $to, $link {
    my $deg_of_assoc = $link.get_degree_of_assoc;
    my $spread_amt   = int( 0.001 * $deg_of_assoc * $self.act);
    $to.increase_activation( $spread_amt );
  }
}

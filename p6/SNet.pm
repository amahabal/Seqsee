class SNet;

# There will only ever be one SNet, making life just a little easier.
# Why would we need this? To do node look up by name, for one.
# To spread activation, for another.

our %.Name2Node;

method get_node($name){ %.Name2Node{$name}  }
method register($node){ %.Name2Node{$node.name} = $node }
method deregister($node){ delete %.Name2Node{$node.name} }

# Thus, we'd use:
# SNet.register($n);
# later... $node = SNet.get_node("n2");

method update_slipnet_activations(){
  for %.Name2Node.values {
    .activation_decay;
    next unless .act == 100;
    .spread_activation;
  }
  for %.Name2Node.values {
    .flush_activation;
  }
  for %.Name2Node.values {
    my $act_percent = $.act/100;
    next unless 0.5 < $act_percent < $act_percent;
    .set_activation(100) if toss($act_percent ** 3);
  }
}

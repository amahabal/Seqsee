package SNet;
use strict;

use SNode;
use SFlags;

our %Str2Node;   # maps "$node" to $node
our %Name2Node; # maps long name to node (long name includes type)


our $node_successor   =   fetch("Other::successor",   create => 1);
our $node_predecessor =   fetch("Other::predecessor", create => 1);
our $node_surprising  =   fetch("Other::surprising",  create => 1);
our $node_extendible  =   fetch("Other::extendible",  create => 1);

for (1 .. 10) {
  my $node = fetch("Number::$_", create => 1, magnitude => $_);
}

#for (1 .. 10) {
#  my $node = fetch("Number::$_")->hardcode_desc_refs;
#}

sub fetch{
  my ($what, %args) = @_;
  if ($what =~ /(.*)::(.*)/) {
    ($what, $args{type}) = ($2, $1);
  }
  my $hashref = $Name2Node{$what};
  if (defined $hashref) {
    # At least one node has this short name
    if (my $type = $args{type}) {
      # Okay, so that limits the choice a lot
      return $hashref->{$type} if $hashref->{$type};
      return $args{create} ? create_node($type, shortname => $what, %args) : undef;
    }
    # If I am here, no specific type has been requested
    my %hash = %$hashref;
    my @keys = keys %hash;
    if (scalar(@keys) == 1) { return $hash{ $keys[0] }; }
    # I have several keys, and no way to choose... I can choose randomly (horrors!) or return undef.... I choose undef for now. Uninformed choice... XXX
    return undef;
  } else {
    # No short name with this node exists!
    if ($args{create}) {
      die "Must have type if I am to create" unless $args{type};
      return create_node($args{type}, shortname => $what, %args);
    } else {
      return undef;
    }
  }
}

sub create_node{
  my ($type, %args) = @_;
  my $package = "SNodeType::$type";
  my $node = $package->new(%args);
  my $shortname = $node->{shortname};
  $Str2Node{$node} = $node;
  $Name2Node{$shortname}{$type} = $node;
  
  my $longname   = $type."::".$shortname;
  if (exists $SNode::DanglingLinks{ $longname }) {
    foreach (@{ $SNode::DanglingLinks{ $longname }}) {
      $_->hardcode_ref;
    }
    delete $SNode::DanglingLinks{ $longname };
  } 
  $node->establish_links;
  $node;
}


# for (1..9) {
#   $Nodes{$_}->add_desc( SDesc->new($Nodes{$_ + 1},
# 				   $Dflag::has,
# 				   "successor",)
# 		      );
# }

# for (2..10) {
#   $Nodes{$_}->add_desc( SDesc->new($Nodes{$_ - 1},
# 				   $Dflag::has,
# 				   "predecessor")
# 		      );
# }

# sub fetch{
#   my $package = shift;
#   my $what    = shift;
#   my %args    = @_;
#   return $Nodes{$what} if exists $Nodes{$what};
#   return undef unless $args{create};
#   $Nodes{$what} = new SNode($what);
# }

1;

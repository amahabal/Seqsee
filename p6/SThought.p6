role SThought;

# Last Updated: Jan 12 2005

method contemplate                      (){...}
method spread_activation_from_components(){...}
method contemplate_add_descriptors      (){...}
method check_if_component_in_stream     (){...}
method magical_halo                     (){...}

method contemplate(){

  # This is a crucial method. Called when a new thought has been added to the stream. The following steps happen:
  # First, possible descriptors get added to this.
  .contemplate_add_descriptors();

  # Next, all the descriptors and stuff closely related to them (together: the magical halo) is checked for presence in the stream. Note that the magical halo is used only for the current object of thought, and other objects in the stream just have a "simple" halo.
  .check_if_component_in_stream();

  # Each component of the description is sent some activation, and it also passes this on.
  .spread_activation_from_components();

  # Another phase of adding descriptions. After this point, perhaps, the thought will soon be antiquated.
  .contemplate_add_descriptors();

}

method spread_activation_from_components(){
  # I do not understand this well yet.
  # Currently, classes using this supply their own versions (null).
  # Ideally, this should be written here as it is perhaps common to all.
  ...
}

method contemplate_add_descriptors(){
  # I understand this even less...
  # But this seems a better candidate for several classes having their own versions.
  ...
}

method check_if_component_in_stream(){
  # This method looks at the entire magical halo of the thought (the components and stuff closely associated with the components), and sees if it reminds of anything. Reminding happens if any component (or almost-component) is present as a component of some recent thought (that is, a thought in the stream).
  # Further, it can launch bond evaluator codelets for potential bonds.

  # We are doing this to form bonds, and hence we are only interested in SObjects:
  return() unless .isa("SObject");

  my %in_stream;
  for .magical_halo -> ($comp) {
    %in_stream{$c} = $c if %SStream::CompStrength.exists($c);
  }
  
  return () unless %in_stream; # No reminding!

  # Now just look at SObjects in the stream, and see if any of their components is also in the halo of the current thought. Also remember how strong the reminding is.

  my @object_thoughts = grep { .isa("SObject") } @SStream::Thoughts;
  return unless @object_thoughts; 
  my @similarity_strengths;

  for @object_thoughts -> ($ot) {
    my $strength = 0;
    for $ot.str_comps -> ($comp) {
      $strength += %SStream::CompStrength{$comp} if %in_stream.exists($comp);
    }
    push @similarity_strengths, $strength;
  }
  
  my $object = $SChooser::By_wt.choose(@object_thoughts, @similarity_strengths);
  return unless $object;
  
  # Now we have an object that is similar in some sense. But we need to find out what the similarity is. We do know what aspects of the old object remind us, in the following way:

  my @common;
  for $object.str_comps -> ($comp) {
    push(@common, $comp) if %in_stream.exists($comp);
  }

  # Post a new codelet to evaluate the potential bond here.
  SApp.post_cc("SThought", "bond_evaluator",
	       :similarity{@common} :current{$_} :older{$object}
	      );

}

method magical_halo(){
  # This is just the union of the halos of all the components. Maybe I should also remember where each bit of the halo comes from, as it'd be useful later. I am not remembering that currently, though:
  my %halo;
  for .components -> ($comp) {
    %halo{$comp} = $comp;
    for $comp.halo -> ($almost_comp) {
      %halo{$almost_comp} = $almost_comp;
    }
  }
  %halo.values;
}

# XXX: What are the potential problems here?
# I do not understand .contemplate_add_descriptors() or .spread_activation_from_components()
# I am perhaps calculating a lot of information twice. Also, when I pass info to the bond scout I do not pass any information about what sort of relationships may exist; For example, if the current object is a <2>, it's magical halo will include a «1», which is also a component of <1>. Now, the bond scout will have to find out what this relationship is. Maybe this relationship can just as easily be stored when calculating the magical_halo, and reused. More thought needed here.

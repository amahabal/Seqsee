role SFascination;
our @.FascOrder;
our %.FascCallBacks;
has %.f;

method update_fascinations($self:){
  for @.FascOrder {
    my $callback = %.FascCallBacks{$_};
    %.f{$_} = $callback($_);
  }
}

method load($packagename){
  $packagename->require;
}

1;

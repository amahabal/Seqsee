package SCF::bond_evaluator;

our $logger;
BEGIN{
  $logger = Log::Log4perl->get_logger("SCF.bond_evaluator");
}
use constant LOGGING_DEBUG => $logger->is_debug;
use constant LOGGING_INFO  => $logger->is_info;


sub run{
  my ($opts) = @_;
  $logger->info("Potential similarities: ", join(", ", map { $_->{str} } @{$opts->{old_halo}})) if LOGGING_INFO;
  # Right now this creates a bond immediately.... XXX should check appropriateness
  my ($left_obj, $right_obj) = sort { $a->{left_edge} <=> $b->{left_edge} } 
    ($opts->{older}, $opts->{current});
  my $bond = SBond->new($left_obj, $right_obj);
  $logger->info("Bond formed: $bond->{str}") if LOGGING_INFO;

  # We already have some idea of how the objects are related: the old_halo is related to the corresponding new_halo, in some way.

  my $oh = $opts->{old_halo};
  my $nh = $opts->{new_halo};
  my $how_many_sim = scalar(@{$oh});

  for (my $i=0; $i < $how_many_sim; $i++) {
    my $old_comp = $oh->[$i];
    my $new_comp = $nh->[$i];
    $logger->info("I will compare $old_comp->{str} of $opts->{older}{str} with $new_comp->{str} of $opts->{current}{str}") if LOGGING_INFO;
    my $bdesc= $opts->{older}->compare($old_comp, $opts->{current}, $new_comp);
    if ($bdesc) {
      $logger->info("Aha! I did find something nice! $bdesc->{str}") if LOGGING_INFO;
      $bond->add_desc($bdesc);
    } else {
      $logger->info("Failed to find any relationship") if LOGGING_INFO;
    }
  }

  $left_obj->bond_insert($bond);
  $right_obj->bond_insert($bond);
  SWorkspace->bond_insert($bond);
  SStream->new_thought($bond);
  
  #XXX Just testing....
  my $gp = SGroup->new($left_obj, $right_obj);
  SWorkspace->group_insert($gp);
  for ($left_obj, $right_obj) {
    $_->group_insert($gp);
  }

}
 
1;

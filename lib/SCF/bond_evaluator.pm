package SCF::bond_evaluator;

our $logger = Log::Log4perl->get_logger("SCF.bond_evaluator");

sub run{
  my ($opts) = @_;
  $logger->info("Potential similarities: ", join(", ", map { $_->{str} } @{$opts->{similarity}}));
  # Right now this creates a bond immediately.... XXX should check appropriateness
  my ($left_obj, $right_obj) = sort { $a->{left_edge} <=> $b->{left_edge} } 
    ($opts->{older}, $opts->{current});
  my $bond = SBond->new($left_obj, $right_obj);
  $logger->info("Bond formed: $bond->{str}");
  $left_obj->bond_insert($bond);
  $right_obj->bond_insert($bond);
  SWorkspace->bond_insert($bond);
}
 
1;

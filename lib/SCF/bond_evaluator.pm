package SCF::bond_evaluator;

our $logger = Log::Log4perl->get_logger("SCF.bond_evaluator");

sub run{
  my ($opts) = @_;
  $logger->info("Potential similarities: ", join(", ", @{$opts->{similarity}}));
}
 
1;

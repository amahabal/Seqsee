package SThought;
use strict;

use Log::Log4perl;
our $logger = Log::Log4perl->get_logger('SThought');

sub contemplate{
  my $thought = shift;
  $thought->contemplate_add_descriptors();
  # Check if the components are already present in the stream somewhere
  $thought->check_if_component_in_stream();
  $thought->spread_activation_from_components();
  $thought->contemplate_add_descriptors();
}

sub spread_activation_from_components{
  die "This Should Never Have Been Called. Not Implemented Yet";
}

sub contemplate_add_descriptors{
  die "This default implementation of contemplate_add_descriptors() just dies: Override this.";
}

sub check_if_component_in_stream{
  my $thought = shift;
  my @in_stream = ();
  foreach my $c ($thought->components()) {
    if (exists $SStream::CompStrength{$c}) {
      push (@in_stream, $c);
    }
  }
  if (@in_stream) {
    $logger->debug("This new thought looks similar to another older thought!");
    SApp::post_cc("SThought", "bond_evaluator", similarity => \@in_stream);
  }
}

1;

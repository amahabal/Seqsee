package SThought;
use strict;

use Log::Log4perl;
our $logger = Log::Log4perl->get_logger('SThought');

sub contemplate{
  my $thought = shift;
  $thought->contemplate_add_descriptors();
  # Check if the components are already present in the stream somewhere
  $thought->check_if_component_in_stream();
  $thought->spread_activation_from_halo();
  $thought->contemplate_add_descriptors();
}

sub spread_activation_from_halo{
  # XXX Blank implementation currently
}

sub contemplate_add_descriptors{
  die "This default implementation of contemplate_add_descriptors() just dies: Override this.";
}

sub check_if_component_in_stream{
  my $thought = shift;
  # Comment out this: even for bonds, we do need reminding
  # unless ($thought->isa("SObject")) {
  #  $logger->debug("No need to check if there is a similar component in the stream: this is not an SObject");
  #  $::STREAM_gui->magical_halo({}) if ::GUI;
  #  return;
  # }
  my %in_stream = ();
  my $magical_halo = $thought->magical_halo();
  $::STREAM_gui->magical_halo($magical_halo) if ::GUI;
  foreach my $c (map {$_->[0]} values %$magical_halo) {
    if (exists $SStream::CompStrength{$c}) {
      $in_stream{$c} =  $magical_halo->{$c}[2];
    }
  }
  return unless %in_stream;

  # For now, I'll return unless we are dealing with an object, as I do not know how I should deal with being reminded of a bond....
  unless ($thought->isa("SObject")) {
    return;
  }

  #XXX Aargh! but we need to choose which thought; This, and the other thought, must both be SObjects, o/w no bond makes sense...
  my @object_thoughts = grep { $_->isa("SObject") } @SStream::Thoughts;
  return unless @object_thoughts;
  ### For each object, see how much it can be reminded of
  my @similarity_strengths;
  my $damping = 1;
  for my $ot (@object_thoughts) {
    my $strength = 0;
    $damping *= 0.8;
    for my $comp (@{$ot->{str_comps}}) {
      next unless exists $in_stream{$comp};
      $strength += $SStream::CompStrength{$comp} * $in_stream{$comp} *$damping;
    }
    push(@similarity_strengths, $strength);
  }
  my $object = $SChooser::By_wt->choose(\@object_thoughts, \@similarity_strengths);
  return() unless $object;

  # @common is the intersection of stuff in the magical halo of current and the halo of the older thought.
  my @common = ();
  for my $comp (@{$object->{str_comps}}) {
    push(@common, $comp) if exists $in_stream{$comp};
  }

  # But we also know where each of these magical halo came from
  my @eff_common = map { $magical_halo->{$_}[1] } @common;

  $logger->debug("This new thought looks similar to another older thought($object->{str})!.");
  SApp::post_cc("SThought", "bond_evaluator", 
		old_halo   => \@common,
		new_halo   => \@eff_common,
		current    => $thought,
		older      => $object,
	       );
}

sub magical_halo{
  my $thought = shift;
  my %halo;
  my %strength;
  my @components = $thought->halo;
  foreach my $comp (@components) {
    $halo{$comp} = [$comp, $comp];
    $strength{$comp}+=2;
    # For each concept in the halo of this concept, add those too. So, for "2" this will be a "3" and a "1", perhaps
    for ($comp->halo) {
      $halo{$_} = [$_, $comp];
      $strength{$_} += 1;
    }
  }
  while (my ($k, $v) = each %halo) {
    $v->[2] = $strength{$k};
  }
  \%halo;
}

1;

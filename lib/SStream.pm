package SStream;
use strict;
use Log::Log4perl;

our $debug_logging;
our $logger;

BEGIN {
  our $logger = Log::Log4perl->get_logger('SStream');
  our $debug_logging = $logger->is_debug();
}



our $DiscountFactor         = 0.8;
our $MaxThoughts            = 10;
our $ThoughtCount           = 0;
our @Thoughts               = ();
our $CurrentThought;
our %CompStrength;
our %ThoughtsList;

sub Reset{
  $ThoughtCount   = 0;
  @Thoughts       = ();
  $CurrentThought = undef;
  %CompStrength   = ();
  %ThoughtsList   = ();
}

sub antiquate_thought{
  return unless $CurrentThought; # Else nothing to antiquate!
  $CurrentThought->{str_comps} = [$CurrentThought->halo()];
  if ($debug_logging) {
    $logger->debug("Antiquating thought $CurrentThought->{str}");
    foreach (@{ $CurrentThought->{str_comps} }) {
      $logger->debug("\thalo component: $_->{str}");
    }
  }
  while ( my ($comp, $strength) = each %CompStrength) {
    $CompStrength{$comp} *= $DiscountFactor;
  }
  unshift(@Thoughts, $CurrentThought);
  foreach my $comp (@{ $CurrentThought->{str_comps} }) {
    $CompStrength{$comp} += $DiscountFactor;
  }
  $ThoughtCount++;
  $CurrentThought = undef;
}

sub new_thought{
  my ($package, $thought) = @_;
  $logger->info("SStream: new thought $thought->{str}");
  $package->add_thought($thought);
  $thought->contemplate;
}

sub add_thought{
  my ($package, $thought) = @_;
  return () if ($CurrentThought and ($thought eq $CurrentThought));
  if (exists $ThoughtsList{$thought}) {
    # Good... so it is somewhere in old thoughts...
    SStream->antiquate_thought() if $CurrentThought;
    @Thoughts = grep { $_ ne $thought } @Thoughts;
    $CurrentThought = $thought;
    recalculate_CompStrength();
    $ThoughtCount = scalar(@Thoughts); # maybe $CurrentThought was undef
  } else {
    SStream->antiquate_thought() if $CurrentThought;
    $CurrentThought = $thought;
    $ThoughtsList{$CurrentThought} = 1;
  }
}

sub maybe_expell_thoughts{
  return unless $ThoughtCount > $MaxThoughts;
  my $excess = $ThoughtCount - $MaxThoughts;
  for (1..$excess) { forget_oldest_thought(); }
}

sub forget_oldest_thought{
  return unless $ThoughtCount;
  my $factor = $DiscountFactor ** $ThoughtCount;
  my $last_thought = pop(@Thoughts);
  $ThoughtCount--;
  foreach my $comp (@{ $last_thought->{str_comps} }) {
    $CompStrength{$comp} -= $factor;
    delete $CompStrength{$comp} unless $CompStrength{$comp};
  }
  delete $ThoughtsList{$last_thought};
}

sub recalculate_CompStrength{
  %CompStrength = ();
  my $multiplicand = 1;
  for my $t (@Thoughts) {
    $multiplicand *= $DiscountFactor;
    foreach (@{$t->{str_comps}}) {
      $CompStrength{$_}+=$multiplicand;
    }
  }
}

1;

class SStream;

our Num      $.DiscountFactor is rw                 = 0.8;
our Int      $.MaxThoughts    is rw                 = 10;
our Int      $.ThoughtCount                         = 0;
our SThought @.Thoughts                             = ();
our SThought $.CurrentThought                       = undef;
our Num      %:CompStrength   is shape(SComponent)  = ();
our Int      %:ThoughtsList   is shape(SThought)    = ();

method Reset(){
  $.ThoughtCount   = 0;
  @.Thoughts       = ();
  $.CurrentThought = undef;
  %:CompStrength   = ();
  %:ThoughtsList   = ();
}

method antiquate_thought(){
  return unless $.CurrentThought; # Else nothing to antiquate!
  *$.CurrentThought.str_comps = $CurrentThought.components();
  %.CompStrength.kv -> $comp, $strength {
    %.CompStrength{$comp} *= $.DiscountFactor;
  }
  unshift(@.Thoughts, $.CurrentThought);
  for *$.CurrentThought.str_comps -> $comp {
    %CompStrength{$comp} += $.DiscountFactor;
  }
  $.ThoughtCount++;
  $.CurrentThought = undef;
}

method new_thought(SThought $thought){
  .add_thought($thought);
  $thought.contemplate;
}

method add_thought(SThought $thought){
  return () if ($CurrentThought and ($thought eq $CurrentThought));
  if (exists %ThoughtsList{$thought}) {
    # Good... so it is somewhere in old thoughts...
    SStream.antiquate_thought() if $.CurrentThought;
    @.Thoughts = grep { $_ ne $thought } @.Thoughts;
    $.CurrentThought = $thought;
    .recalculate_CompStrength();
    $.ThoughtCount = @.Thoughts.elems; # maybe $CurrentThought was undef
  } else {
    SStream.antiquate_thought() if $.CurrentThought;
    $.CurrentThought = $thought;
    %ThoughtsList{$.CurrentThought} = 1;
  }
}

method maybe_expell_thoughts{
  return unless $.ThoughtCount > $.MaxThoughts;
  my $excess = $.ThoughtCount - $.MaxThoughts;
  for (1..$excess) { .forget_oldest_thought(); }
}

method forget_oldest_thought{
  return unless $.ThoughtCount;
  my $factor = $.DiscountFactor ** $.ThoughtCount;
  my $last_thought = @.Thoughts.pop;
  $.ThoughtCount--;
  for *$last_thought.str_comps -> $comp {
    %.CompStrength{$comp} -= $factor;
    delete %.CompStrength{$comp} unless %.CompStrength{$comp};
  }
  delete %ThoughtsList{$last_thought};
}

method recalculate_CompStrength{
  %.CompStrength = ();
  my $multiplicand = 1;
  for @.Thoughts -> $t {
    $multiplicand *= $DiscountFactor;
    for *$t.str_comps {
      %.CompStrength{$_}+=$multiplicand;
    }
  }
}

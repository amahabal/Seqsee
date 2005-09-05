package SStream;
use strict;

my $DiscountFactor            = 0.8;
my $MaxOlderThoughts          = 10;
my $OlderThoughtCount         = 0;
my @OlderThoughts             = (); # for order
my %ThoughtsSet               = (); # another view, includes CurrentThought
my %ComponentStrength         = ();

my $CurrentThought;


#### method clear
# description    :Gets stream back into the state where there are no thoughts, no trace of what happened
# argument list  :()
# return type    :
# context of call:void
# exceptions     :

sub clear{
    $OlderThoughtCount   = 0;
    @OlderThoughts       = ();
    $CurrentThought      = undef;
    %ComponentStrength   = ();
}


#### method add_thought
# description    :adds a thought
# argument list  :(SThought $thought)
# return type    :
# context of call:void
# exceptions     :

sub add_thought{
    @_ == 2 or die "new thought takes two arguments";
    my ( $package, $thought ) = @_;
    
    return if $thought eq $CurrentThought;

    if (exists $ThoughtsSet{$thought}) { #okay, so this is an older thought
        unshift( @OlderThoughts, $CurrentThought ) if $CurrentThought;
        @OlderThoughts = grep { $_ ne $thought } @OlderThoughts;
        $CurrentThought = $thought;
        _recalculate_Compstrength();
        $OlderThoughtCount = scalar(@OlderThoughts);
    }

    else {
        SStream->antiquate_current_thought() if $CurrentThought;
        $CurrentThought = $thought;
        $OlderThoughtCount++;
        $ThoughtsSet{$CurrentThought} = 1;
        _maybe_expell_thoughts();
    }

}


#### method _maybe_expell_thoughts
# description    :expells thoughs if old thought limit exceeded
# argument list  :
# return type    :
# context of call:
# exceptions     :
sub _maybe_expell_thoughts{
    return unless $OlderThoughtCount > $MaxOlderThoughts;
    for (1 .. $OlderThoughtCount - $MaxOlderThoughts) {
        delete $ThoughtsSet{ pop @OlderThoughts };
    }
    $OlderThoughtCount = $MaxOlderThoughts;
    _recalculate_Compstrength();
}


#### method _recalculate_Compstrength
# description    :calculates the strength of components from scratch
# argument list  :
# return type    :
# context of call:void
# exceptions     :


sub _recalculate_Compstrength{
    %ComponentStrength = ();
    my $multiplicand = 1;
    for my $t (@OlderThoughts) {
        $multiplicand *= $DiscountFactor;
        foreach my $component ( $t->get_fringe() ) {
            $ComponentStrength{ $component } += $multiplicand;
        }
    }
}


#### method init
# description    :puts in the initial thought(s), to get us off the ground.
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub init{
    die "not implemented";
}

1;

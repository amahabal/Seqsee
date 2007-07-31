package Global;

our $Steps_Finished = 0;            # Number od codelets/thoughts run.
our $Break_Loop;                    # Boolean: Break out of main loop after this iteration?
our $CurrentCodelet;                # Current codelet.
our $CurrentCodeletFamily;          # Family of current codelet.
our $CurrentRunnableString;         # String representation, for logging purposes.
our $AtLeastOneUserVerification;    # Bool: Has the user ever said 'yes' ? to 'is this next?'
our $TestingOptionsRef;             # Global options when in testing mode.
our $TestingMode;                   # Bool: are we running in testing mode?
our %ExtensionRejectedByUser;       # Rejected continuations.
our $LogString;                     # Generated log string. See log.cong
our %PossibleFeatures;              # Possible features, to catch typos in -f option.
our %Feature;                       # Features turned on from commandline with -f.
our $Options_ref;                   # Global options, includes defaults, configs and commandline
our @RealSequence;                  # The sequence in reality. Seqsee maybe unaware of several
                                    # terms, in test mode.
our $InitialTermCount;              # Number of terms at start.
our $TimeOfLastNewElement = 0;      # When was the last element added?
our $TimeOfNewStructure   = 0;      # When was the last group created or element added?

our $InterstepSleep = 0;            # In milli-seconds
our $Sanity;                        # Do sanity check after each step?
our %Hilit;                         # 0bjects to hi1lit; can have 1/2as values

our $BestRule;                      # Best rule seen so far.
our $BestRuleApp;
our $RecentPromisingRule;           # A recently seen rule that might be right.
our $RecentPromisingRuleApp;
our %GroupStrengthByConsistency;    # Strength confered on groups by consistency with rules.

our $AcceptableTrustLevel = 0.5;    # Trust level above which questions can be asked.
                                    # Gets adjusted programatically ..

%PossibleFeatures = map { $_ => 1 } qw(relnact rules onlyfwd chooseright assumecompleteblocks);
$LogString = '';

sub clear {
    $Steps_Finished             = 0;
    $AtLeastOneUserVerification = 0;
    %ExtensionRejectedByUser    = ();
    $LogString                  = '';
    %Hilit                      = ();
    $BestRule                   = undef;
    $RecentPromisingRule        = undef;
    %GroupStrengthByConsistency = ();
}

sub ClearHilit {
    %Hilit = ();
}

sub Hilit {
    my ($value) = shift;
    $Hilit{$_} = $value for @_;
}

sub SetRuleAppAsBest {
    my ($ruleapp) = @_;
    $BestRuleApp = $ruleapp;
    $BestRule    = $ruleapp->get_rule();
    UpdateGroupStrengthByConsistency();
}

sub SetRuleAppAsRecent {
    my ($ruleapp) = @_;
    $RecentPromisingRuleApp = $ruleapp;
    $RecentPromisingRule    = $ruleapp->get_rule();
    UpdateGroupStrengthByConsistency();
}

sub UpdateGroupStrengthByConsistency {
    %GroupStrengthByConsistency = ();
    if ($BestRuleApp) {
        for ( @{ $BestRuleApp->get_items } ) {
            $GroupStrengthByConsistency{$_} += 40;
        }
    }
    if ($RecentPromisingRuleApp) {
        for ( @{ $RecentPromisingRuleApp->get_items } ) {
            $GroupStrengthByConsistency{$_} += 40;
        }
    }
}

1;

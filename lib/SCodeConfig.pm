package CodeConfig;
use strict;
our %Post;

$Post{"SThought"}{"bond_evaluator"} = sub {
    my %attr     = @_;
    my $how_freq = 1;

    # No need to toss, always post
    my $codelet = new SCodelet( "bond_evaluator", 50, %attr, );
    SCoderack->add_codelet($codelet);
};

$Post{"bond_evaluator"}{"group_evaluator"} = sub {
    my %attr     = @_;
    my $how_freq = 1;

    # No need to toss, always post
    my $codelet = new SCodelet( "group_evaluator", 50, %attr, );
    SCoderack->add_codelet($codelet);
};

$Post{"StartUp"}{"all"} = sub {
    my %attr = @_;
    my $how_freq;
    my $codelet;

    # Always Post next codelet, so no toss
    $codelet = new SCodelet( "reader", 50, %attr, );
    SCoderack->add_codelet($codelet);
};
$Post{"Background"}{"all"} = sub {
    my %attr = @_;
    my $how_freq;
    my $codelet;
    $how_freq = 0.5;
    if ( SUtility::toss($how_freq) ) {
        my $codelet = new SCodelet( "reader", 50, %attr, );
        SCoderack->add_codelet($codelet);
    }
};

1;

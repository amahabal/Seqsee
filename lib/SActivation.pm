package SActivation;
use strict;
use warnings;
use Carp;

use constant RAW_ACTIVATION       => 0;    # Index.
use constant RAW_SIGNIFICANCE     => 1;    # Index.
use constant STABILITY_RECIPROCAL => 2;    # Index.
use constant REAL_ACTIVATION      => 3;    # Index.
use constant MODIFIER_NODE_INDEX  => 4;    # Index. *only* used for links.

my $RAW_ACTIVATION       = RAW_ACTIVATION();
my $RAW_SIGNIFICANCE     = RAW_SIGNIFICANCE();
my $STABILITY_RECIPROCAL = STABILITY_RECIPROCAL();
my $REAL_ACTIVATION      = REAL_ACTIVATION();
my $MODIFIER_NODE_INDEX  = MODIFIER_NODE_INDEX();

sub GetRawActivation       { return $_[0]->[RAW_ACTIVATION]; }
sub GetRawSignificance     { return $_[0]->[RAW_SIGNIFICANCE]; }
sub GetStabilityReciprocal { return $_[0]->[STABILITY_RECIPROCAL]; }

our @PRECALCULATED;
for ( 0 .. 200 ) {
    $PRECALCULATED[$_] = 0.4815 + 0.342 * atan2( 12 * ( $_ / 100 - 0.5 ), 1 );    # change!
}

my $Initial_Raw_Activation       = 1;
my $Initial_Raw_Significance     = 1;
my $Initial_Stability_Reciprocal = 1 / 50;
my $Initial_Real_Activation = $PRECALCULATED[ $Initial_Raw_Activation + $Initial_Raw_Significance ];

# Note that new assumes positions mentioned later...
sub new {
    my $package = shift;
    bless [
        $Initial_Raw_Activation,  $Initial_Raw_Significance, $Initial_Stability_Reciprocal,
        $Initial_Real_Activation, 0,
    ], $package;
}

our $DECAY_CODE = qq{
\$_->[$RAW_ACTIVATION]-- if \$_->[$RAW_ACTIVATION] > 1;
\$_->[$RAW_SIGNIFICANCE] -= \$_->[$STABILITY_RECIPROCAL] if \$_->[$RAW_SIGNIFICANCE] > 1;
\$_->[$REAL_ACTIVATION] = \$PRECALCULATED[\$_->[$RAW_ACTIVATION] + \$_->[$RAW_SIGNIFICANCE]];
};

our $SPIKE_CODE = qq{
\$spike ||=1;
\$_->[$RAW_ACTIVATION]+= \$spike;
if (\$_->[$RAW_ACTIVATION] > 99) {
  \$_->[$RAW_SIGNIFICANCE] += 2;
  \$_->[$RAW_ACTIVATION] = 95;
  if (\$_->[$RAW_SIGNIFICANCE] > 99) {
    \$_->[$RAW_SIGNIFICANCE] = 95;
    my \$stab = 1 / \$_->[$STABILITY_RECIPROCAL];
    \$_->[$STABILITY_RECIPROCAL] = 1 / (\$stab + 3);
  }
}
\$_->[$REAL_ACTIVATION] = \$PRECALCULATED[\$_->[$RAW_ACTIVATION] + \$_->[$RAW_SIGNIFICANCE]];
};

*Decay = eval qq{sub {\$_ = \$_[0]; $DECAY_CODE }};

*DecayMany = eval qq{
sub {
    \@_ == 2 or confess "DecayMany needs 2 args";
    my ( \$arr_ref, \$cnt ) = \@_;
    for my \$i ( 1 .. \$cnt ) {
        \$_ = \$arr_ref->[ \$i ];
        $DECAY_CODE;
    }
    }
};

*Spike = eval qq{
sub {
    my \$spike;
    ( \$_, \$spike ) = \@_;
    $SPIKE_CODE;
    return \$_->[REAL_ACTIVATION];
}
};

package SLinkActivation;

my $MODIFIER_NODE_INDEX = $SActivation::MODIFIER_NODE_INDEX;

sub new {
    my ( $package, $modifier_index ) = @_;
    my $activation = SActivation->new();
    $activation->[$MODIFIER_NODE_INDEX] = $modifier_index;
}

1;

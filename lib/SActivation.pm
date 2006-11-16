package SActivation;
use strict;
use warnings;
use Carp;

use constant RAW_ACTIVATION   => 0;
use constant RAW_SIGNIFICANCE => 1;
use constant STABILITY        => 2;
use constant TIME_STEPS       => 3;
use constant REAL_ACTIVATION  => 4;

my $RAW_ACTIVATION   = RAW_ACTIVATION();
my $RAW_SIGNIFICANCE = RAW_SIGNIFICANCE();
my $STABILITY        = STABILITY();
my $TIME_STEPS       = TIME_STEPS();
my $REAL_ACTIVATION  = REAL_ACTIVATION();

sub GetRawActivation               { return $_[0]->[RAW_ACTIVATION]; }
sub GetRawSignificance             { return $_[0]->[RAW_SIGNIFICANCE]; }
sub GetStability                   { return $_[0]->[STABILITY]; }
sub GetTimeToDecrementSignificance { return $_[0]->[TIME_STEPS]; }

our @PRECALCULATED;
for ( 0 .. 200 ) {
    $PRECALCULATED[$_] = 0.4815 + 0.342 * atan2( 12 * ( $_ / 100 - 0.5 ), 1 );    # change!
}

# Note that new assumes positions mentioned later...
sub new {
    my $package = shift;
    bless [ 1, 1, 100, 100, $PRECALCULATED[2] ], $package;
}

our $DECAY_CODE = qq{
\$_->[$REAL_ACTIVATION] = \$PRECALCULATED[ --\$_->[$RAW_ACTIVATION] + \$_->[$RAW_SIGNIFICANCE] ];
\$_->[$RAW_ACTIVATION] ||= 1;
unless ( --\$_->[$TIME_STEPS] ) {
    --\$_->[$RAW_SIGNIFICANCE];
    \$_->[$RAW_SIGNIFICANCE] ||= 1;
    \$_->[$TIME_STEPS] = \$_->[$STABILITY];
}
};

our $SPIKE_CODE = qq{
\$_->[$RAW_ACTIVATION] += \$spike;
if ( \$_->[$RAW_ACTIVATION] > 100 ) {
    \$_->[$RAW_ACTIVATION] = 100;
    \$_->[$RAW_SIGNIFICANCE]++;
    if ( \$_->[$RAW_SIGNIFICANCE] > 100 ) {
        \$_->[$RAW_SIGNIFICANCE] = 100;
        \$_->[$STABILITY]++;
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

1;

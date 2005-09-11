package S;

use SSet;
use SErr;
use SBindings;
use SInstance;
use SPos;

use SCodelet;
use SCoderack;
use SCodeConfig;

use SInt;
use SBuiltObj;

use SCat;
use SCat::ascending;
use SCat::descending;
use SCat::mountain;
use SCat::number;
use SCat::literal;

use SElement;
use SWorkspace;

use SBlemishType;
use SBlemishType::double;
use SBlemishType::triple;
use SBlemishType::ntimes;

use SCat::Derive::assuming;
use SCat::Derive::blemished;
use SCat::Derive::blemish_count;
use SCat::Derive::blemish_position;

use SReln;
use SThought;
use SStream;

use SLog;

# use SUtil;

our $ascending  = $SCat::ascending::ascending;
our $descending = $SCat::descending::descending;
our $mountain   = $SCat::mountain::mountain;
our $literal    = $SCat::literal::literal;
our $number     = $SCat::number::number;

our $double = $SBlemishType::double::double;
our $triple = $SBlemishType::triple::triple;
our $ntimes = $SBlemishType::ntimes::ntimes;

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain, $double, $triple, $ntimes];

1;

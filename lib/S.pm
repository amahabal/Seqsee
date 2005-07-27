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

use SBlemish;
use SBlemish::double;
use SBlemish::triple;
use SBlemish::ntimes;

use SCat::Derive::assuming;
use SCat::Derive::blemished;
use SCat::Derive::blemish_count;
use SCat::Derive::blemish_position;

# use SUtil;

our $ascending  = $SCat::ascending::ascending;
our $descending = $SCat::descending::descending;
our $mountain   = $SCat::mountain::mountain;
our $literal    = $SCat::literal::literal;
our $number     = $SCat::number::number;

our $double = $SBlemish::double::double;
our $triple = $SBlemish::triple::triple;
our $ntimes = $SBlemish::ntimes::ntimes;

1;

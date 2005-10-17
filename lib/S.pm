package S;

use SSet;
use SErr;
use SBindings;
use SInstance;
use SPos;
use SSet;

use SCodelet;
use SCoderack;
use SCodeConfig;

use SObject;
# Next 2 lines need removal
#use SInt;
#use SBuiltObj;

use SMetonym;
use SMetonymType;
use SMulti;

#use SCat;
use SCat::OfObj;
use SCat::ascending;
use SCat::descending;
use SCat::mountain;
use SCat::sameness;
#use SCat::number;
#use SCat::literal;

use SElement;
use SWorkspace;

# Need to convert the next four
use SCat::Derive::assuming;
use SCat::Derive::blemished;
use SCat::Derive::blemish_count;
use SCat::Derive::blemish_position;

use SRel;
use SThought;
use SStream;
use SWorkspace;

use SLog;

# use SUtil;

our $ASCENDING  = $SCat::ascending::ascending;
our $DESCENDING = $SCat::descending::descending;
our $MOUNTAIN   = $SCat::mountain::mountain;
#our $literal    = $SCat::literal::literal;
#our $number     = $SCat::number::number;
our $SAMENESS    = $SCat::sameness::sameness;

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain];

1;

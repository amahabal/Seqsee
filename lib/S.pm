package S;

use List::MoreUtils;
use List::Util;
use Scalar::Util;

use SLog;
use SInsertList;

use SSet;
use SErr;
use SChoose;
use SBindings;
use SInstance;
use SPos;
use SSet;
use SFasc;


use SCodelet;
use SAction;
use SCoderack;
use SCodeConfig;

use SMetonym;
use SMetonymType;
use SMulti;

#use SCat;
use SCat::OfObj;
use SCat::OfCat;
use SCat::ascending;
use SCat::descending;
use SCat::mountain;
use SCat::sameness;
#use SCat::number;
use SCat::literal;
use SCat::reln_based;

use SObject;
use SAnchored;
use SElement;
use SWorkspace;

# Need to convert the next four
use SCat::Derive::assuming;
use SCat::Derive::blemished;
use SCat::Derive::blemish_count;
use SCat::Derive::blemish_position;

#use SReln;
use SReln::Simple;
use SReln::Compound;
use SReln::Position;
use SReln::MetoType;
use SThought;
use SStream;
use SWorkspace;
 

# use SUtil;

our $ASCENDING  = $SCat::ascending::ascending;
our $DESCENDING = $SCat::descending::descending;
our $MOUNTAIN   = $SCat::mountain::mountain;
our $LITERAL    = $SCat::literal::literal;
#our $number     = $SCat::number::number;
our $SAMENESS    = $SCat::sameness::sameness;
our $RELN_BASED = $SCat::reln_based::reln_based;

our $DOUBLE = SMetonymType->new(
    { category => $S::SAMENESS,
      name     => "each",
      info_loss=> {length => 2},
  }
        );

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain];

package DIR;
use enum qw{BITMASK: LEFT RIGHT
            ENUM: BOTH=3 NEITHER=0 UNKNOWN=4
        };

package POS_MODE;
use enum qw{BITMASK: FORWARD BACKWARD
            
        };

package METO_MODE;
use enum qw{ENUM: NONE=0 SINGLE ALLBUTONE ALL};

package EXTENDIBILE;
use enum qw{ENUM: NO=0 UNKNOWN PERHAPS};

1;

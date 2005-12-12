package S;

use SLog;

use SSet;
use SErr;
use SChoose;
use SBindings;
use SInstance;
use SPos;
use SSet;

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

use SObject;
use SAnchored;
use SElement;
use SWorkspace;

# Need to convert the next four
use SCat::Derive::assuming;
use SCat::Derive::blemished;
use SCat::Derive::blemish_count;
use SCat::Derive::blemish_position;

use SReln;
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

our $DOUBLE = SMetonymType->new(
    { category => $S::SAMENESS,
      name     => "each",
      info_loss=> {length => 2},
  }
        );

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain];

1;

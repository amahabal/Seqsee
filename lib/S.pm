package S;

use List::Util;
use Scalar::Util;

use SNode;
use SHistory;

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
use SCat::ad_hoc;

use SObject;
use SAnchored;
use SElement;
use SWorkspace;

# Need to convert the next four
#use SCat::Derive::assuming;
#use SCat::Derive::blemished;
#use SCat::Derive::blemish_count;
#use SCat::Derive::blemish_position;

#use SReln;
use SReln::Simple;
use SReln::Compound;
use SReln::Position;
use SReln::MetoType;
use SThought;
use SStream;
use SWorkspace;
 
use SCF::All;

# use SUtil;

our $ASCENDING  = $SCat::ascending::ascending;
our $DESCENDING = $SCat::descending::descending;
our $MOUNTAIN   = $SCat::mountain::mountain;
our $LITERAL    = $SCat::literal::literal;
#our $number     = $SCat::number::number;
our $SAMENESS    = $SCat::sameness::sameness;
our $RELN_BASED = $SCat::reln_based::reln_based;
our $AD_HOC     = $SCat::ad_hoc::AD_HOC;

our $DOUBLE = SMetonymType->new(
    { category => $S::SAMENESS,
      name     => "each",
      info_loss=> {length => 2},
  }
        );

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain];

package DIR;
our $LEFT = bless {text => 'left'}, 'DIR';
our $RIGHT = bless {text => 'right'}, 'DIR';
our $UNKNOWN = bless {text => 'unknown'}, 'DIR';
our $NEITHER = bless {text => 'neither'}, 'DIR';

sub LEFT{ $LEFT }
sub RIGHT{ $RIGHT }
sub UNKNOWN{ $UNKNOWN }
sub NEITHER{ $NEITHER }

sub as_text{
    my ( $self ) = @_;
    return $self->{text};
}


package POS_MODE;
use enum qw{BITMASK: FORWARD BACKWARD
            
        };

package METO_MODE;
use enum qw{ENUM: NONE=0 SINGLE ALLBUTONE ALL};

package EXTENDIBILE;
use enum qw{ENUM: NO=0 UNKNOWN PERHAPS};

package RELN_SCHEME;
use enum qw{ENUM: CHAIN=1};

1;

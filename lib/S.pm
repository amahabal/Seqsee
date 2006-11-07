package S;

use Global;

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

use SMetonym;
use SMetonymType;
use SMulti;

use SCat;
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
use SRelnType::Compound;
use SRelnType::Simple;
use SThought;
use SStream;
use SWorkspace;

use SCF::All;
use SThought::All;

# use SUtil;

our $ASCENDING  = $SCat::ascending::ascending;
our $DESCENDING = $SCat::descending::descending;
our $MOUNTAIN   = $SCat::mountain::mountain;
our $LITERAL    = $SCat::literal::literal;

#our $number     = $SCat::number::number;
our $SAMENESS   = $SCat::sameness::sameness;
our $RELN_BASED = $SCat::reln_based::reln_based;
our $AD_HOC     = $SCat::ad_hoc::AD_HOC;

our $DOUBLE = SMetonymType->new(
    {   category  => $S::SAMENESS,
        name      => "each",
        info_loss => { length => 2 },
    }
);

our $cats_and_blemish_ref = [ $ascending, $descending, $mountain ];

package DIR;
our $LEFT    = bless { text => 'left' },    'DIR';
our $RIGHT   = bless { text => 'right' },   'DIR';
our $UNKNOWN = bless { text => 'unknown' }, 'DIR';
our $NEITHER = bless { text => 'neither' }, 'DIR';

sub LEFT    {$LEFT}
sub RIGHT   {$RIGHT}
sub UNKNOWN {$UNKNOWN}
sub NEITHER {$NEITHER}

sub PotentiallyExtendible {
    my ($self) = @_;
    return ( $self eq $LEFT or $self eq $RIGHT );
}

sub as_text {
    my ($self) = @_;
    return $self->{text};
}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    return new SInsertList( $self->{text}, '' );
}

package POS_MODE;
our $FORWARD  = bless { mode => 'FORWARD' },  'POS_MODE';
our $BACKWARD = bless { mode => 'BACKWARD' }, 'POS_MODE';

sub FORWARD  {$FORWARD}
sub BACKWARD {$BACKWARD}

sub as_text {
    my ($self) = @_;
    return $self->{mode};
}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    return new SInsertList( $self->{mode}, '' );
}

sub get_memory_dependencies { return; }

sub serialize {
    my ($self) = @_;
    return $self->{mode};
}

sub deserialize {
    my ($package, $str) = @_;
    no strict 'vars';
    return ${$str};
}

package METO_MODE;
our $NONE      = bless { mode => 'NONE' },      'METO_MODE';
our $SINGLE    = bless { mode => 'SINGLE' },    'METO_MODE';
our $ALLBUTONE = bless { mode => 'ALLBUTONE' }, 'METO_MODE';
our $ALL       = bless { mode => 'ALL' },       'METO_MODE';
our $OTHER     = bless { mode => 'OTHER' },     'METO_MODE';
sub NONE      {$NONE}
sub SINGLE    {$SINGLE}
sub ALLBUTONE {$ALLBUTONE}
sub ALL       {$ALL}
sub OTHER     {$OTHER}

sub as_text {
    my ($self) = @_;
    return $self->{mode};
}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    return new SInsertList( $self->{mode}, '' );
}

sub is_position_relevant {
    my ($self) = @_;
    if ( $self eq $SINGLE or $self eq $ALLBUTONE ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_metonymy_present {
    my ($self) = @_;
    return ( $self eq $NONE ) ? 0 : 1;
}

sub get_memory_dependencies { return; }

sub serialize {
    my ($self) = @_;
    return $self->{mode};
}

sub deserialize {
    my ($package, $str) = @_;
    no strict 'vars';
    return ${$str};
}

package EXTENDIBILE;
our $NO      = 0;
our $PERHAPS = bless { mode => 'PERHAPS' }, 'EXTENDIBILE';
our $UNKNOWN = bless { mode => 'UNKNOWN' }, 'EXTENDIBILE';
sub NO      {$NO}
sub PERHAPS {$PERHAPS}
sub UNKNOWN {$UNKNOWN}

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    return new SInsertList( $self->{mode}, '' );
}

package RELN_SCHEME;
our $NONE = 0;
our $CHAIN = bless { type => 'CHAIN' }, 'RELN_SCHEME';
sub NONE  {$NONE}
sub CHAIN {$CHAIN}

1;

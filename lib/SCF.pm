#####################################################
#
#    Package: SCF
#
#####################################################
#####################################################

package SCF;
use strict;
use Carp;
use Class::Std;
use base qw{Exporter};

our @EXPORT = qw( ContinueWith );

sub ContinueWith {
    scalar(@_) == 1 or confess "ContinueWith takes a single argument!";
    UNIVERSAL::isa($_[0], 'SThought') or confess "ContinueWith takes a thought as argument";
    SStream->add_thought($_[0]);
}

1;

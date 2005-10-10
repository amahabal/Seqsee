#####################################################
#
#    Package: SMulti
#
#####################################################
#   A single file where a lot of the multi will sit
#####################################################
# A list of multimethods defined here:
# * seq_clone

package SMulti;
use strict;
use Carp;
use Class::Multimethods;
use base qw{};



# multi: seq_clone ( $ )
# Cloning a scalar
#
#    Trivial
#

multimethod  seq_clone => qw($) => sub {
    return $_[0]; 
};

1;

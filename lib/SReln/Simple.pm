#####################################################
#
#    Package: SReln::Simple
#
#####################################################
#   Package for maintianing simple relations between integers.
#####################################################

package SReln::Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};


# variable: %str_of
#    The string representation of the relation
my %str_of :ATTR(:get<text>);



# method: BUILD
# Builds.
#
#    Just needs the text. But maybe should also need the two objects. XXX probably change that!

sub BUILD{
    my ( $self, $id, $arg_ref ) = @_;
    $str_of{$id} = $arg_ref->{text} or confess "Need text!";
}



# multi: find_reln ( #, # )
# Relation between two numbers
#
#    This one is simple: can be same, succ, pred or nothing
#     
#    Feels like I am writing this for the 100th time!
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:

multimethod find_reln => ('#', '#') => sub {
    my ( $a, $b ) = @_;
    if ($a == $b) {
        return SReln::Simple->new( { text => "same" });
    } elsif ($a + 1 == $b ) {
        return SReln::Simple->new( { text => "succ" });
    } elsif ($a - 1 == $b) {
        return SReln::Simple->new( { text => "pred" });
    }

    return;
};





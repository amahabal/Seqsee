package SThought;
use strict;

use Class::Std;
use Carp;

use SThought::SElement;
use SThought::AreRelated;
 
# variable: %fringe_of
#    Keeps the fringe of the the thought
my %stored_fringe_of :ATTR( :get<stored_fringe>, :set<stored_fringe> );


# variable: %_Type2Class
#    Converts type to a class name
my %_Type2Class = 
    qw(   SElement        SThought::SElement
                         
           );

# method: create
# creates a though given the core
#
sub create{
    my ( $package, $core ) = @_;
    my $type = ref $core;
    my $class = $_Type2Class{$type};

    confess "Don't know how to create object of type $type"
        unless $class;

    return $class->new( { core => $core });
}


1;



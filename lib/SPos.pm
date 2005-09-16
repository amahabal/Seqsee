#####################################################
#
#    Package: SPos
#
#####################################################
#   Manages positions
#####################################################

package SPos;
use strict;

use SPosFinder;
use SPos::Absolute;
use SPos::Named;
use SPos::The;

use Carp;

my %Memoize;
my %Memoize_the;




# method: new
#    -
#
#    usage:
#     new SPos(3)
#
#    description:
#      Creates a new Spos object. When $what is a
#
#        positive integer - position from start. 1 is first
#        negative integer - position from end. -1 is last
#        string           - a named position (like "peak")
#
#    parameter list:
#        $what - 
#
#    return value:
#      
#
#    possible exceptions:


sub new {
    my $package = shift;
    my $what    = shift;
    return $Memoize{$what} if $Memoize{$what};
    my %args = @_;
    croak
        "A position must have a number or a string as the first argument to new."
        unless $what;
    my $self;
    if ( $what =~ m/^-?\d+$/ ) {
        $self = new SPos::Absolute( { index => $what } );
    }
    else {
        $self = new SPos::Named( { str => $what } );
    }
    $self->set_name($what);
    $Memoize{$what} = $self;
}

sub new_the {
    my ( $package, $cat ) = @_;
    my $self = ( $Memoize_the{$cat} ||= SPos::The->new( { cat => $cat } ) );
    $self->set_name( "the " . $cat->get_name() );
    return $self;
}

1;

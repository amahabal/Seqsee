package SPos;
use strict;

use SPosFinder;
use SPos::Global;
use SPos::Global::Absolute;
use SPos::Named;
use SPos::The;

use Carp;

my %Memoize;
my %Memoize_the;

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
        $self = new SPos::Global::Absolute( { index => $what } );
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

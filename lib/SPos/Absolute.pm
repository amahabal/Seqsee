package SPos::Absolute;
use strict;
use Carp;

use base "SPos";

use Class::Std;
my %finder_of :ATTR;
my %name_of :ATTR(:set<name> :get<name> );


sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $index = $opts_ref->{index};
    my $sub;

    croak "index is one based; index 0 illegal" unless $index;
    if ( $index > 0 ) {
        $sub = sub {
            my $built_obj = shift;
            return [ $index - 1 ]
                unless $index > scalar( @{ $built_obj->items } );
            SErr::Pos::OutOfRange->throw("out of range: $built_obj, $index");
        };
    }
    else {
        $sub = sub {
            my $built_obj = shift;
            my $eff_index = scalar( @{ $built_obj->items } ) + $index;
            return [$eff_index] unless $eff_index < 0;
            SErr::Pos::OutOfRange->throw("out of range: $built_obj, $index");
        };
    }
    my $finder = new SPosFinder( { sub => $sub, multi => 0 } );
    $finder_of{$id} = $finder;
}

sub find_range {
    my ( $self, $built_obj ) = @_;
    $finder_of{ ident $self}->find_range( $built_obj );
}

1;

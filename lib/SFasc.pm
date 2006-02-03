#####################################################
#
#    Package: SFasc
#
#####################################################
#####################################################

package SFasc;
use strict;
use Carp;
use Class::Std;
use base qw{};

sub get_fascination{
    my ( $self, $fasc ) = @_;
    my $type = ref $self;
    my $subu = $ {"$type::" . "FASCINATION"}{$fasc} 
        or confess "fascination $fasc not defined for $self of type $type";
    $subu->($self);
}

1; 

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

# Somewhat hacky, am not sure how to do this right.
# Will be a number between 0 and 100.
our %strength_of :ATTR(:get<strength> :set<strength>);

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $strength_of{$id} = $opts_ref->{strength} || 0;
}


sub get_fascination {
    my ( $self, $fasc ) = @_;
    my $type = ref $self;
    my $subu = ${ "$type::" . "FASCINATION" }{$fasc}
        or confess "fascination $fasc not defined for $self of type $type";
    $subu->($self);
}

1;

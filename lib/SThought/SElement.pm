#####################################################
# 
#    Package: SThought::SElement
#
#####################################################
#   Thoughts of type "SElement"
#####################################################

package SThought::SElement;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SThought};


# variable: %core_of
#    The core
my %core_of :ATTR();


# variable: %magnitude_of
#    The magnitude
my %magnitude_of :ATTR( :get<magnitude>);


# method: BUILD
# Builds, given the core
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    $magnitude_of{$id} = $core->get_mag;
}



# method: get_fringe
# Just the literal category, and categories the core belongs to
#
sub get_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    my $mag = $magnitude_of{$id};
    push @ret, [$S::LITERAL->build({ structure => [$mag] }), 100];

    # my $cats_ref = $core_of{$id}->get_categories();
    for (@{$core_of{$id}->get_categories()}) {
            push @ret, [ $_, 80];
    }

    return \@ret;
}

# method: get_extended_fringe
# Just literal categories of mag +- 1
#
sub get_extended_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    my $mag = $magnitude_of{$id};
    push @ret, [$S::LITERAL->build({ structure => [$mag + 1] }), 50];
    push @ret, [$S::LITERAL->build({ structure => [$mag - 1] }), 50];

    return \@ret;
}



# method: get_actions
# Launch some codelets
#
#    * very low priority codelet that looks for more instances
#
sub get_actions{
    my ( $self ) = @_;
    my $id = ident $self;

    # Currently returns nothing.
    return;
}



# method: as_text
# 
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;
    my $core = $core_of{$id};
    my ($left, $right, $mag) = ( $core->get_left_edge,
                                 $core->get_right_edge,
                                 $magnitude_of{$id}
                                     );
    return "SThought::SElement [$left, $right] $mag";
}


1;

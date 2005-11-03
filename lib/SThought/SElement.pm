#####################################################
#
#    Package: SThought::SElement
#
# Thought Type: SElement
#
# Core:
#
# 
# Fringe:
#
# Extended Fringe:
#
# Actions:
#
#####################################################
#   
#####################################################
package SThought::SElement;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};


# variable: %core_of
#  The Core
my %core_of :ATTR( :get<core>);

# variable: %magnitude_of
#    The magnitude
my %magnitude_of :ATTR( :get<magnitude>);


# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    $magnitude_of{$id} = $core->get_mag;
}

# method: get_fringe
# 
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
# 
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
# 
#
sub get_actions{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    return @ret;
}

# method: as_text
# textual representation of thought
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

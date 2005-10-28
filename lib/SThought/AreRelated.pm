#####################################################
#
#    Package: SThought::AreRelated
#
#####################################################
#   Are the two thoughts related?
#####################################################

package SThought::AreRelated;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SThought};


# variable: %a_of
#    First arg
my %a_of :ATTR;

# variable: %b_of
#    Second arg
my %b_of :ATTR;

# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $a_of{$id} = $opts_ref->{a} or confess "Need a";
    $b_of{$id} = $opts_ref->{b} or confess "Need b";
}

# method: get_fringe
# 
#
sub get_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    return \@ret;
}

# method: get_extended_fringe
# 
#
sub get_extended_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

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
    my $a_txt = $a_of{$id}->as_text;
    my $b_txt = $b_of{$id}->as_text;

    return "SThought::AreRelated ($a_txt, $b_txt)";
}

1;

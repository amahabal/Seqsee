#####################################################
#
#    Package: SThought::SReln_Compound
#
# Thought Type: SReln_Compound
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
package SThought::SReln_Compound;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};


# variable: %core_of
#  The Core
my %core_of :ATTR( :get<core>);
my %base_cat_of :ATTR( );
my %base_meto_mode_of :ATTR;
my %base_pos_mode_of :ATTR;
my %unchanged_bindings_of_of :ATTR;
my %changed_bindings_of_of :ATTR;
my %metonymy_reln_of :ATTR;


# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    $base_cat_of{$id} = $core->get_base_category;
    $base_meto_mode_of{$id} = $core->get_base_meto_mode;
    $base_pos_mode_of{$id} = $core->get_base_pos_mode;
    $unchanged_bindings_of_of{$id} = $core->get_unchanged_bindings_ref;
    $changed_bindings_of_of{$id} = $core->get_changed_bindings_ref;
    $metonymy_reln_of{$id} = $core->get_metonymy_reln;
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

    return "SThought::SReln_Compound";
}

1;
 

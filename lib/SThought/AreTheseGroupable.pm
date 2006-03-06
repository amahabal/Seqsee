#####################################################
#
#    Package: SThought::AreTheseGroupable
#
# Thought Type: AreTheseGroupable
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
package SThought::AreTheseGroupable;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};
use List::Util qw{min max};

my %items_of :ATTR();
my %reln_of :ATTR();

# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $items_of{$id} = $opts_ref->{items} || confess;
    $reln_of{$id}  = $opts_ref->{reln};
}

# method: get_fringe
# 
#
sub get_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;
    foreach (@{$items_of{$id}}) {
        push @ret, [$_, 20];
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

    return \@ret;
}

# method: get_actions
# 
#
sub get_actions{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    # Check if these are already grouped...
    # to do that, we need to find the left and right edges
    my (@left_edges, @right_edges);
    for (@{$items_of{$id}}) {
        push @left_edges, $_->get_left_edge;
        push @right_edges, $_->get_right_edge;
    }
    my $left_edge  = min(@left_edges);
    my $right_edge = max(@right_edges);
    my $is_covering = SWorkspace->is_there_a_covering_group($left_edge, $right_edge);
    return if $is_covering;

    my $new_group;
    eval { $new_group = SAnchored->create(@{$items_of{$id}})};
    if (my $e = $EVAL_ERROR) {
        if (UNIVERSAL::isa($e, "SErr::HolesHere")) {
            return;
        } 
        die $e;
    }

    $new_group->set_underlying_reln($reln_of{$id});
    SWorkspace->add_group($new_group);
    # confess "@SWorkspace::OBJECTS New group created: $new_group, and added it to w/s";

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::AreTheseGroupable";
}

1;

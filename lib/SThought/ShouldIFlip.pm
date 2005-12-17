#####################################################
#
#    Package: SThought::ShouldIFlip
#
# Thought Type: ShouldIFlip
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
package SThought::ShouldIFlip;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};


# variable: %reln_of
#  The Reln
my %reln_of :ATTR( :get<reln>);


# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $reln = $reln_of{$id} = $opts_ref->{reln} or confess "Need reln"; 
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

    my $reln = $reln_of{$id};
    #if this is part of a group, the answer is NO, don't flip!
    my ($l, $r) = $reln->get_extent();
    if (SWorkspace->is_there_a_covering_group($l, $r)) {
        return;
    } else {
        #okay, so we *may* switch... lets go ahead for now
        my $act = SAction->new( {family => 'flipReln',
                                 urgency => 100,
                                 args => { reln => $reln },
                             });
        push @ret, $act;
    }

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::ShouldIFlip";
}

1;

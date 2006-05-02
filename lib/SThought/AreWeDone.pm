#####################################################
#
#    Package: SThought::AreWeDone
#
# Thought Type: AreWeDone
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
package SThought::AreWeDone;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use Smart::Comments;
use English qw(-no_match_vars);
use base qw{SThought};

my %group_of :ATTR();

# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $group_of{$id} = $opts_ref->{group} or confess "Need group";
    ### Thought AreWeDone created!
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

    my $gp = $group_of{$id};
    my $span = $gp->get_span;
    my $total_count = $SWorkspace::elements_count;
    ### $span, $total_count
    
    if ($main::AtLeastOneUserVerification and ($span / $total_count) > 0.8) {
        # This very well may be it!
        if ($gp->get_left_edge() != 0) {
            if ($gp->get_left_extendibility() ne EXTENDIBILE::NO()) {
                my $action = SAction->new( {
                    family => 'AttemptExtension',
                    urgency => 80,
                    args => { core => $gp,
                              direction => DIR::LEFT()
                          },
                        });
                push @ret, $action;
            } else {
                if ($total_count - $span == $gp->get_left_edge) {
                    main::message("I believe this group has a blemish at the beginning");
                }
            }
        } else {
            # so flush left
            if ($span == $total_count) {
                #Bingo!
                if ($gp->get_right_extendibility() ne EXTENDIBILE::NO()) {
                    #great. 
                    main::update_display();
                    main::message("I believe I got it");
                } else {
                    main::update_display();
                    my $rejected = join(", ", keys %::EXTENSION_REJECTED_BY_USER);
                    my $msg = "I think I am stuck. ";
                    $msg .= "You have already rejected $rejected as possible continuation(s)";
                    main::message($msg);
                }
            } else {
                my $action = SAction->new( {
                    family => 'AttemptExtension',
                    urgency => 80,
                    args => { core => $gp,
                              direction => DIR::RIGHT()
                          },
                        });
                push @ret, $action;                
            }
        }
    }

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::AreWeDone";
}

1;

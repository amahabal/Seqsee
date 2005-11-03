#####################################################
#
#    Package: SThought::SReln_Simple
#
# Thought Type: SReln_Simple
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
package SThought::SReln_Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};
 

# variable: %core_of
#  The Core
my %core_of :ATTR( :get<core>);


# variable: %str_of
#    The string of teh core
my %str_of :ATTR();

# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    $str_of{$id} = $core->get_text;
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

    my $core = $core_of{$id};
    my $str = $str_of{$id};
    #XXX what follows should happen probabilistically etc...
    if ($str eq "same") {
        my $action =
            SAction->new({ family  => 'FindIfGroupable',
                           urgency => 100,
                           args   => {
                               category => $S::SAMENESS,
                               items => [ $core->get_first(),
                                          $core->get_second(),
                                              ],
                                   },
                       });
        # print "New FindIfGroupable action suggested\n";
        push @ret, $action;
    }

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::SReln_Simple";
}

1;

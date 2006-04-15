#####################################################
#
#    Package: SThought::SAnchored
#
# Thought Type: SAnchored
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
package SThought::SAnchored;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};


# variable: %core_of
#  The Core
my %core_of :ATTR( :get<core>);


# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    # main::message( "An SAnchored object was thought about!");
}

# method: get_fringe
# 
#
sub get_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my $core = $core_of{$id};

    my @ret;
    my $structure = $core_of{$id}->get_structure();
    push @ret, [$S::LITERAL->build({ structure => $structure }), 100];

    my $rel = $core->get_underlying_reln();
    push(@ret, [$rel, 50]) if $rel;

    my @cats = @{$core->get_cats()};
    push @ret, map { [$_, 100] } @cats;
    #if (@cats) {
        #print "Cats: '", $cats[0], "' ", ref($cats[0]), "\n";
        #main::message("$core belongs to: " .scalar(@cats). "@cats");
    #}


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
    my $core = $core_of{$id};

    my @ret;

    # extendibility checking...
    if ($core->get_right_extendibility()) {
        my $cl = new SCodelet("AttemptExtension", 100,
                              { core => $core,
                                direction => DIR::RIGHT(),
                            }
                                  );
        push @ret, $cl;
    }

    my $poss_cat = $core->get_underlying_reln()->suggest_cat();
    if ($poss_cat) {
        my $is_inst = $core->is_of_category_p($poss_cat)->[0];
        # main::message("$core is of $poss_cat? '$is_inst'");
        unless ($is_inst) { #XXX if it already known, skip!
            my $cl = new SCodelet("CheckIfInstance", 100, 
                                  {
                                      obj => $core,
                                      cat => $poss_cat
                                          });
            push @ret, $cl;
        }
    }

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::SAnchored";
}

1;

#####################################################
#
#    Package: SNode
#
#####################################################
#   Things that can have activations
#####################################################

package SNode;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use base qw{};

my %core_of :ATTR;
my %activation_of :ATTR( :get<activation> :set<activation>);
my %updated_activation_of :ATTR();
my %depth_of :ATTR();
my %name_of :ATTR( :get<name>);

our %MEMOIZE;
our $DECAY_RATE;

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $core_of{$id} = $opts_ref->{core} or confess "no core for snode!!";
    $depth_of{$id} = $opts_ref->{depth} or confess "need depth";
    $activation_of{$id} = $opts_ref->{activation};
    $name_of{$id} = "Node " . $core_of{$id}->as_text();

    confess "depth should be a number bigger than 1" if ($depth_of{$id} < 1);

    ## Created node: $name_of{$id}

    $activation_of{$id} = 0;
}

sub create{
    my ( $package, $core, $depth, $activation ) = @_;

    $depth or confess "need depth";
    $activation ||= 0;

    return $MEMOIZE{$core} if exists $MEMOIZE{$core};

# XXX(Assumption): [2006/09/25] Node always a thought.
    if ($core->isa('SThought')) {
        return $MEMOIZE{$core} = SNode->new({ 
            core => $core,
            depth => $depth,
            activation => $activation,
                });
    } else {
        return $MEMOIZE{$core} = SNode->new({ 
            core => SThought->create($core),
            depth => $depth,
            activation => $activation,
                });
    }

}

sub decay{
    my ( $self, $timesteps ) = @_;
    my $id = ident $self;

    $updated_activation_of{$id} = 
        int ($activation_of{$id} * 
                 ( $DECAY_RATE ** ($timesteps / $depth_of{$id} )));
}

sub Decay_All{
    my ( $package ) = @_;
    while (my($k, $v) = each %MEMOIZE) {
        $v->decay();
    }
    while (my($k, $v) = each %MEMOIZE) {
        my $id = ident $v;
        $activation_of{$id} = $updated_activation_of{$id};
    }
}

sub excite{
    my ( $self, $amt ) = @_;
    $amt ||= 10;
    my $id = ident $self;

    my $new_val = ($activation_of{$id} += $amt);
    if ($new_val > 100) {
        $activation_of{$id} = 100;
    }

}

sub clear{
    my ( $package ) = @_;
    %MEMOIZE = ();
}

sub init{
    my ( $package, $opts_ref ) = @_;
    clear();
    $DECAY_RATE = $opts_ref->{DecayRate} or die;
}



1; 



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
my %activation_of :ATTR( :get<activation>);
my %updated_activation_of :ATTR();
my %depth_of :ATTR();

our %MEMOIZE;
our $DECAY_RATE;

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $core_of{$id} = $opts_ref->{core} or confess "no core for snode!!";
    $depth_of{$id} = $opts_ref->{depth} or confess "need depth";

    confess "depth should be a number bigger than 1" if ($depth_of{$id} < 1);

    $activation_of{$id} = 0;
}

sub create{
    my ( $package, $core, $depth ) = @_;

    $depth or confess "need depth";

    if (exists $MEMOIZE{$core}) {
        return $MEMOIZE{$core};
    }

    if ($core->isa('SThought')) {
        return $MEMOIZE{$core} = SNode->new({ 
            core => $core,
            depth => $depth
                });
    } else {
        return $MEMOIZE{$core} = SNode->new({ 
            core => SThought->create($core),
            depth => $depth
                });
    }

}

sub decay{
    my ( $self, $timesteps ) = @_;
    my $id = ident $self;

    $updated_activation_of{$id} = $activation_of{$id} * 
        ( $DECAY_RATE ** ($timesteps / $depth_of{$id} ));
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
        $activation_of{$id} = $new_val;
    }

}

sub clear{
    my ( $package ) = @_;
    %MEMOIZE = ();
}

sub init{
    my ( $package, $opts_ref ) = @_;
    $DECAY_RATE = $opts_ref->{DecayRate};
}



1; 



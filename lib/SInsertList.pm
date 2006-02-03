#####################################################
#
#    Package: SInsertList
#
#####################################################
#####################################################
 
package SInsertList;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use base qw{};

sub new{
    my ( $package, @rest ) = @_;
    my @ret;
    while (@rest) {
        my ($l, $tag) = splice(@rest, 0,2);
        $tag ||= "";
        push @ret, [$l, $tag];
    }
    bless \@ret, $package; 
}

sub indent{
    my ( $self, $dep ) = @_;
    my $replace = "\n" . "  " x $dep;
    for (@$self) {
        $_->[0] =~ s#\n#$replace#g;
    }
    $self;
}

sub append{
    my ( $self, @rest ) = @_;
    my $l = new SInsertList(@rest);
    push @$self, @$l;
    $self;
}

sub concat{
    my ( $self, $otherlist ) = @_;
    ### $otherlist
    push @$self, @$otherlist;
    $self;
}

1;



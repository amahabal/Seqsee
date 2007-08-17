#####################################################
#
#    Package: ResultOfGetConflicts
#
#####################################################
#####################################################

package ResultOfGetConflicts;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %original_object_of : ATTR(:name<original>);
my %exact_conflict_of : ATTR(:name<exact>);
my %other_conflicts_of : ATTR(:name<other>);

use overload (
    q{bool} => sub {
        my ($self) = @_;
        my $id = ident $self;
        if ( $exact_conflict_of{$id} or @{ $other_conflicts_of{$id} } ) {
            return 1;
        }
        else {
            return;
        }
    },
    fallback => 1,
);

sub Resolve {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    my $IgnoreConflictWith;
    if ( $opts_ref and exists( $opts_ref->{IgnoreConflictWith} ) ) {
        $IgnoreConflictWith = $opts_ref->{IgnoreConflictWith};
    }

    if ( my $exact = $exact_conflict_of{$id} ) {
        SWorkspace->FightUntoDeath(
            {   challenger => $self,
                incumbent  => $exact
            }
        ) or return;
    }

    for my $some_other ( @{ $other_conflicts_of{$id} } ) {
        next if $some_other eq $IgnoreConflictWith;
        next if ( !SWorkspace::__CheckLiveness($some_other) );
        SWorkspace->FightUntoDeath(
            {   challenger => $self,
                incumbent  => $exact
            }
        ) or return;
    }

    return 1;
}

1;

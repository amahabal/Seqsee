#####################################################
#
#    Package: SPos::Forward
#
#####################################################
#####################################################

package SPos::Forward;
use strict;
use Carp;
use Class::Std;
use base qw{SPos};

my %index_of : ATTR(:get<index>);    # Index: 1 means "first".

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $index_of{$id} = $opts_ref->{index};
}

sub find_range {
    my ( $self, $object ) = @_;
    my $index = $index_of{ ident $self};
    my $size  = $object->get_parts_count();

    $size == 0     and SErr::Pos::OutOfRange->throw();
    $index < 1     and SErr::Pos::OutOfRange->throw();
    $index > $size and SErr::Pos::OutOfRange->throw();

    return [ $index - 1 ];
}

1;


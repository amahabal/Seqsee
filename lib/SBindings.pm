package SBindings;
use strict;
use Carp;
use Class::Std;
use SBindings::Blemish;

my %values_of_of : ATTR( :get<values_of> );
my %blemishes_of : ATTR( :get<blemishes> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $blemishes_of{$id} = [];
}

sub add_blemish {
    my ( $self, $blemish ) = @_;
    UNIVERSAL::isa( $blemish, "SBindings::Blemish" )
        or croak "Need SBindings::Blemish";
    push( @{ $blemishes_of{ ident $self} }, $blemish );
}

sub set_value_of {
    my ( $self, $what_ref ) = @_;
    my $val_ref = ( $values_of_of{ ident $self} ||= {} );
    while ( my ( $k, $v ) = each %$what_ref ) {
        $val_ref->{$k} = $v;
    }
}

sub as_hash : HASHIFY {
    my ($self) = shift;
    return { %{ $values_of_of{ ident $self} } };
}

sub get_where {
    my ($self) = shift;
    return [ map { $_->get_where } @{ $blemishes_of{ ident $self} } ];
}

sub get_real {
    my ($self) = shift;
    return [ map { $_->get_real } @{ $blemishes_of{ ident $self} } ];
}

sub get_starred {
    my ($self) = shift;
    return [ map { $_->get_starred } @{ $blemishes_of{ ident $self} } ];
}

sub get_blemished {
    my ($self) = shift;
    return scalar @{ $blemishes_of{ ident $self} };
}

1;

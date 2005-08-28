package SBlemishType::triple;

my $builder = sub {
    my ( $self, $args ) = @_;
    my $object = $args->{what};
    return SBuiltObj->new_deep( $object, $object, $object );
};

my $guesser = {
    what => sub {
        my ( $self, $bo ) = @_;
        $bo->items()->[0];
        }
};

my $guesser_flat = {
    what => sub {
        my ( $self, @bo ) = @_;
        return if @bo % 3;
        return SBuiltObj->new_deep( @bo[ 0 .. ( @bo / 3 ) - 1 ] );
        }
};

our $triple = new SBlemishType(
    {   builder         => $builder,
        empty_ok        => 1,
        empty_what      => SBuiltObj->new_deep(),
        guesser_of      => $guesser,
        guesser_flat_of => $guesser_flat,
    }
);

1;

package SCat;
use strict;
use Carp;

sub derive_blemished {
    my ( $self, $options_ref ) = @_;
    my $blemish = $options_ref->{blemish} or croak "Must provide a blemish";
    my $position = $options_ref->{position}
        or croak "Must provide a position";
    croak "Blemish must be a SBlemishType"
        unless UNIVERSAL::isa( $blemish, "SBlemishType" );
    croak "Position must be a SPos"
        unless UNIVERSAL::isa( $position, "SPos" );

    my $new_cat = new SCat(
        {   builder => sub {
                my ( $blemished, $opts_ref ) = @_;
                my $bo = $self->build($opts_ref);
                return $bo->apply_blemish_at( $blemish, $position );
            },
            instancer => sub {
                croak "unimplemented";
            },
        }
    );
    $new_cat;
}

1;

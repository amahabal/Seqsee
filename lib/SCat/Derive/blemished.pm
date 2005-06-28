package SCat;
use strict;
use Carp;

sub derive_blemished {
  my ( $self, $options_ref ) = @_;
  my $blemish  = $options_ref->{blemish}  or croak "Must provide a blemish";
  my $position = $options_ref->{position} or croak "Must provide a position";
  croak "Blemish must be a SBlemish"
    unless UNIVERSAL::isa( $blemish, "SBlemish" );
  croak "Position must be a SPos" unless UNIVERSAL::isa( $position, "SPos" );

  my $new_cat = new SCat(
    {
      builder => sub {
        shift;
        my $bo = $self->build(@_);
        return $bo->apply_blemish_at( $blemish, $position );
      },
      instancer => sub {
        croak "unimplemented";
      },
      empty_ok       => 0,
      guesser_pos_of => {},
      guesser_of     => {},

    }
  );
  $new_cat;
}

1;

package SCat::number;
use strict;
use Carp;
use SCat;

our %Memoize;

our $number = new SCat(
  {
    builder => sub {
      my ( $self, $args_ref ) = @_;
      croak "need mag" unless exists $args_ref->{mag};

      my $magnitude = $args_ref->{mag};

      return $Memoize{$magnitude} if $Memoize{$magnitude};

      my $ret = new SCat(
        {
          builder => sub {
            return SBuiltObj->new( { items => [$magnitude] } );
          },
          instancer => sub {
            my ( $self, $builtobj ) = @_;
            my $bindings = new SBindings;
            if ( $builtobj->structure_is( [$magnitude] ) ) {

              # Life is easy...
              return $bindings;
            }

	    # Now check if the object belongs to some blemished category, whose what has that structure...
            my $bl_cats = $builtobj->get_blemish_cats();
            while ( my ( $bl, $what ) = each %$bl_cats ) {
              if ( $what->structure_is( [$magnitude] ) ) {
                $bindings->{_blemished} = 1;
                $bindings->{blemish}    = $bl;
                return $bindings;
              }
            }
            return undef;

          },
          guesser_of     => {},
          guesser_pos_of => {},
        }
      );

      $ret->add_cat( $self, $args_ref );

      $Memoize{$magnitude} = $ret;
      $ret;
    },
    guesser_pos_of => {},
    empty_ok       => 0,
    guesser_of     => {},
  }
);
my $cat = $number;

$cat->add_attributes(qw/mag/);

1;

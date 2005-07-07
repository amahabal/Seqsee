package SCat;
use strict;

sub derive_assuming {
  my ( $self, $assuming_ref ) = @_;
  my %assuming = %$assuming_ref;
  my $name = $self->get_name(). ", with ";
  $name .= " $_ => $assuming{$_}," for keys %assuming;
  chop $name;
  my $new_cat  = new SCat(
    {
     name => $name,
      attributes => [],
      builder    => sub {
        shift;
        my $opts = shift;
        $self->build( { %assuming, %$opts } );
      },
      instancer => sub {
        shift;
        my %assuming = %assuming;
        my $bindings = $self->is_instance(@_);
        return undef unless $bindings;

        while ( my ( $k, $v ) = each %assuming ) {
          return undef unless $bindings->get_values_of()->{$k} eq $v;
        }
        return $bindings;
      },
      empty_ok       => $self->get_empty_ok,
    }
  );

  $new_cat->set_att( $self->get_att );

  $new_cat;

}

1;

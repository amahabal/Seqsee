package SCat;
use strict;

sub derive_assuming{
  my ($self, %assuming) = @_;
  my $new_cat = new SCat;
  $new_cat->{att} = $self->{att} - (new Set::Scalar(keys %assuming));
  $new_cat->{builder} = sub{
    shift;
    $self->build(%assuming, @_);
  };
  $new_cat->{instancer} = sub {
    shift;
    my $bindings = $self->is_instance(@_);
    return undef unless $bindings;
    while (my ($k, $v) = each %assuming) {
      return undef unless $bindings->{$k} eq $v;
    }
    return $bindings;
  };

  $new_cat;
}

1;

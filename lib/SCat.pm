package SCat;
use strict;
use SUtil;
use SBuiltObj;
use Set::Scalar;

our %Cats;

sub new{
  my $package = shift;
  my $self = bless {}, $package;

  $self->{att} = new Set::Scalar;
  

  $self;
}

sub add_attributes{
  my $self = shift;
  $self->{att}->insert(@_);
}

sub build{
  my $self = shift;
  return $self->{builder}->($self, @_);
}

sub is_instance{
  my $self = shift;
  my $builtobj = UNIVERSAL::isa($_[0], "SBuiltObj") ?
    $_[0] : SBuiltObj->new()->set_items(@_);
  return $self->{instancer}->($self, $builtobj);
}

sub subcat_assuming{
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

package SBlemish::double;
use SBlemish;
use SBindings;

our $double = new SBlemish;
my $blemish = $double;

$blemish->{blemisher} = 
  sub {
    my ($blemish, $object) = @_;
    return new SBuiltObj($object, $object);
  };

$blemish->{instancer} = 
  sub {
    my ($blemish, $object) = @_;
    my $items = $object->items;
    return undef unless scalar(@$items) == 2;
    if (ref $items->[0]) {
      return undef unless $items->[0]->compare_deep($items->[1]);
      return new SBindings(what => $items->[0]);
    }
    return undef if ref $items->[1];
    return SBindings->new(what => $items->[0]) if $items->[0] eq $items->[1];
    return undef;
  };


1;

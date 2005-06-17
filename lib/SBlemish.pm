package SBlemish;
use Perl6::Attributes;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  $self;
}

sub blemish{
  my $self = shift;
  my $object = shift;
  my $ret = $.blemisher->($self, $object, @_);
  $ret->add_cat($self->get_blemish_category, what => $object);
  $ret;
}

sub unblemish{
  my $self = shift;
  return $.unblemisher->($self, @_);
}

sub is_blemished{
  my $self = shift;
  my $obj  = shift;
  $.instancer->($self, $obj);
}

sub get_blemish_category{
  my $self = shift;
  $self->{blemish_cat} ||= $self->make_blemish_category;
}

sub make_blemish_category{
  my $self;
  my $ret = new SCat;
  $ret->{builder} = $.blemisher;
  $ret->{instancer} = $.instancer;
  $ret->{_blemished} = $self;
  $self->{blemish_cat} = $ret;
  $ret;
}

1;

package SPos;
use Carp;

my %Memoize;

sub new{
  my $package = shift;
  my $what    = shift;
  return $Memoize{$what} if $Memoize{$what};
  my %args    = @_;
  die "A position must have a number or a string as the first argument to new." unless $what;
  my $sub = $args{sub} || generate_sub($what);
  my $self = bless { name => $what, sub => $sub, %args }, $package;
  $Memoize{$what} = $self;
  $self;
}

sub set_sub{
  my ($self, $sub) = @_;
  $self->{sub} = $sub;
  $self;
}

sub generate_sub{
  my $what = shift;
  if ($what =~ /^ -? \d+ $/x) {
    # This is a number!
    my $index = $what;
    $index = $index - 1 if $index > 0; # convert to 0 based
    return sub {
      my $built_obj = shift;
      my $subobj = $built_obj->items()->[$index];
      return undef unless defined $subobj;
      return $subobj if ref $subobj;
      return SBuiltObj->new()->set_items($subobj);
    }
  }

  # If we get here, what we have is a string... the object had better know what to do with it!

  return sub {
    my $built_obj = shift;
    my $delegate_to_sub = $built_obj->get_position_finder($what);
    confess "Unable to find out position '$what' for object: don't know how to do this for this object!" unless $delegate_to_sub;
    $delegate_to_sub->($built_obj);
  }
}

1;

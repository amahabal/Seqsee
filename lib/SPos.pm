package SPos;
use Perl6::Attributes;
use Carp;

my %Memoize;

sub new{
  my $package = shift;
  my $what    = shift;
  return $Memoize{$what} if $Memoize{$what};
  my %args    = @_;
  die "A position must have a number or a string as the first argument to new." unless $what;
  my $sub = generate_sub($what); #XXX need option to specify sub at creation time
  my $self = bless { name => $what, rangesub => $sub, %args }, $package;
  $Memoize{$what} = $self;
  $self;
}

sub set_sub{
  my ($self, $sub) = @_;
  $.sub = $sub;
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
      if ($index < 0) {
	my $eff_index = scalar(@{$built_obj->items}) + $index;
	return [ $eff_index ] unless $eff_index < 0; # out of range o/w
	return [scalar(@{$built_obj->items})]; # return an out-of-range value
      } else {
	return [ $index ];
      }
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

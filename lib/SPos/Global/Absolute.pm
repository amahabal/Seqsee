package SPos::Global::Absolute;
use base 'SPos::Global';
use SErr;

our %Memoize;

sub new{
  my ( $package, $index ) = @_;
  return $Memoize{$index} if $Memoize{$index};
  my $sub;
  
  die "index is one based; index 0 illegal" unless $index;
  if ($index > 0) {
    $sub = sub { 
      my $built_obj = shift;
      return [$index - 1] unless $index > scalar(@{$built_obj->items});
      SErr::Pos::OutOfRange->throw("out of range: $built_obj, $index");
    };
  } else {
    $sub = sub {
      my $built_obj = shift;
      my $eff_index = scalar(@{$built_obj->items}) + $index;
      return [ $eff_index ] unless $eff_index < 0;
      SErr::Pos::OutOfRange->throw("out of range: $built_obj, $index");
    }; 
  }
  my $finder = new SPosFinder(sub => $sub, multi => 0);
  $Memoize{$index} = SPos::Global::new( $package, finder => $finder ); 
  #XXX SUPER in the line above??
}

1;

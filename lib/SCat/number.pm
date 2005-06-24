package SCat::number;
use SCat;

our %Memoize;

our $number = new SCat;
my $cat = $number;

$cat->add_attributes(qw/mag/);
$cat->{builder} = sub {
  my ($self, %args) = @_;
  die "need mag" unless exists $args{mag};

  my $magnitude = $args{mag};

  return $Memoize{$magnitude} if $Memoize{$magnitude};

  my $ret = new SCat;

  $ret->add_cat($self, {});

  $ret->{builder} = sub {
    return SBuiltObj->new({ items => [ $magnitude ]});
  };
  
  $ret->{instancer} = sub {
    my ($self, $builtobj) = @_;
    my $bindings = new SBindings;
    if ($builtobj->structure_is([$magnitude])) {
      # Life is easy...
      return $bindings;
    } 
    # Now check if the object belongs to some blemished category, whose what has that structure...
    my $bl_cats = $builtobj->get_blemish_cats();
    while (my ($bl, $what) = each %$bl_cats) {
      if ($what->structure_is([$magnitude])) {
	$bindings->{_blemished} = 1;
	$bindings->{blemish} = $bl;
	return $bindings;
      }
    }
    return undef;
  };

  $Memoize{$magnitude} = $ret;
  $ret;
};

1;

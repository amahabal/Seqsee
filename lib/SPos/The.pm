package SPos::The;
use Class::Std;
use Carp;
use base 'SPos';

my %cat_of :ATTR;
my %name_of :ATTR( :get<name> :set<name>);
 
sub BUILD{
  my ( $self, $id, $opts ) = @_;
  $cat_of{$id} = $opts->{cat} || croak "need cat";
}

sub find_range{
  my ( $self, $built_obj ) = @_;
  my $cat = $cat_of{ident $self};
  UNIVERSAL::isa( $cat, "SCat" ) or croak "need SCat";
  my @matching;
  my @items = @{ $built_obj->items() };
  for (my $i=0; $i<@items; $i++) {
    push(@matching, $i) if $cat->is_instance($items[$i]);
  }
  return unless @matching;
  SErr::Pos::MultipleNamed->throw("Several objects matching cat")
      if @matching > 1;
  return [ $matching[0] ];
}

1;

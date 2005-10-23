package SPos::The;
use Class::Std;
use Carp;
use base 'SPos';

my %cat_of : ATTR;
my %name_of : ATTR( :get<name> :set<name> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $cat_of{$id} = $opts->{cat} || croak "need cat";
    UNIVERSAL::isa( $cat_of{$id}, "SCat::OfObj" ) or croak "need SCat::OfObj";

}

sub find_range {
    my ( $self, $built_obj ) = @_;
    my $cat = $cat_of{ ident $self};
    my @matching;
    my @items = @{ $built_obj->get_parts_ref };
    for ( my $i = 0; $i < @items; $i++ ) {
        push( @matching, $i ) if $cat->is_instance( $items[$i] );

        #print "$items[$i]\tmatching now: @matching\n";
    }
    return unless @matching;
    SErr::Pos::MultipleNamed->throw("Several objects matching cat")
        if @matching > 1;
    return [ $matching[0] ];
}

1;

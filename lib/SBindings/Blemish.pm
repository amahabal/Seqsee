package SBindings::Blemish;

use Class::Std;

my %where_of :ATTR( :get<where> :set<where>);
my %starred_of :ATTR( :get<starred> :set<starred> );
my %real_of :ATTR( :get<real> :set<real>);

sub BUILD{
  my ( $self, $id, $opts_ref ) = @_;
  $where_of{$id} = $opts_ref->{where};
  $starred_of{$id} = $opts_ref->{starred};
  $real_of{$id} = $opts_ref->{real};
}

1;

package Perf::Version;
use ModuleSets::Standard;
use ModuleSets::Seqsee;

my %Major_of : ATTR(:name<major>);
my %Minor_of : ATTR(:name<minor>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $string = $opts_ref->{string};
    $string =~ s#\s##g;

    ( $Major_of{$id}, $Minor_of{$id} ) = split( /:/, $string );
}

sub _cmp {
    my ( $a, $b ) = @_;
    my ( $a1, $a2, $b1, $b2 ) =
      map { ( $_->get_major(), $_->get_minor() ) } ( $a, $b );
    return $a1 <=> $b1 || $a2 <=> $b2;
}

use overload '<=>' => \&_cmp;

1;


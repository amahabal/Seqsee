#####################################################
#
#    Package: SRelnType::Simple
#
#####################################################
#####################################################

package SRelnType::Simple;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %string_of : ATTR;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $string_of{$id} = $opts_ref->{string};
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $reln ) = @_;
        my $string = $reln->get_text();
        return $MEMO{$string} ||= $package->new( { string => $string } );
    }

    sub resuscicate {
        my ( $package, $string ) = @_;
        return $MEMO{$string} ||= $package->new( { string => $string } );
    }

}

sub as_text {
    my ($self) = @_;
    return $string_of{ident $self};
}

sub as_dump {
    my ($self) = @_;
    return $string_of{ident $self};
}

1;


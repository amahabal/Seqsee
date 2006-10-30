#####################################################
#
#    Package: SLTM::Platonic
#
#####################################################
#   Memory core for things corresponding to objects in the workspace
#####################################################

package SLTM::Platonic;
use strict;
use Carp;
use Class::Std;
use base qw{};

our %StructureString_of :ATTR();

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $StructureString_of{$id} = $opts_ref->{structure};
}

{
    my %MEMO = ();
    sub create{
        my ( $package, $structure_string ) = @_;
        return $MEMO{$structure_string} ||= $package->new( { structure => $structure_string });
    }
}

sub as_text{
    my ( $self ) = @_;
    return $StructureString_of{ident $self};
}

sub as_dump{
    my ( $self ) = @_;
    return $StructureString_of{ident $self};
}

sub resuscicate{
    my ( $package, $string ) = @_;
    return $package->create( $string );
}



1;



#####################################################
#
#    Package: SMetonymType
#
#####################################################
#    A metonym type just keeps enough information of a metonym to check that two metonyms are essentially the same.
#####################################################

package SMetonymType;
use strict;
use Carp;
use Class::Std;
use base qw{};


# variable: %category_of
#    Category the metonymy is based on
my %category_of :ATTR( :get<category> );


# variable: %meto_name_of
#    Name of metonym
my %meto_name_of :ATTR( :get<name> );


# variable: %info_loss_of
#    What information was lost?
my %info_loss_of :ATTR( :get<info_loss> );



# method: BUILD
# Builds
#

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;

    $category_of{$id}  = $opts_ref->{category}  || die "Need category";
    $meto_name_of{$id} = $opts_ref->{name}      || die "Need name";
    $info_loss_of{$id} = $opts_ref->{info_loss} || die "Need info_loss";
}


1;

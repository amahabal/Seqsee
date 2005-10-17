#####################################################
#
#    Package: SMetonym
#
#####################################################
#   A specific metonym of one object
#    
#   This is intended to be a replacement for SBlemish. I am going to stop using the word blemish, prefering metonym instead. 
#    
#   A metonym would include the category that the object belongs to that allows this slippage, and the name of the slippage.
#####################################################

package SMetonym;
use strict;
use Carp;
use Class::Std;
use Scalar::Util qw{weaken};
use base qw{};


# variable: %category_of
#    What category allowed this slippage?
my %category_of :ATTR( :get<category> );


# variable: %meto_name_of
#    What is the name of this slippage?
my %meto_name_of :ATTR( :get<name> );


# variable: %starred_of
#    What is the more "idealized" version of the "real object the exists in the world"? 
#     
#    In the slippage [2 2] ===> 2, 2 is the starred version
my %starred_of :ATTR( :get<starred> );


# variable: %unstarred_of
#    The object in the real world
#     
#    [2 2] is the unstarred version above.
#     
#    Remember:
#    The link to unstarred should probably be weakened. If that object is the only one with a strong link to this object, it will take this with it when it dies.
my %unstarred_of :ATTR( :get<unstarred> );



# variable: %info_loss_of
#    What information is lost in the process of going from unstarred to starred? Should be enough information to recreate the object.
my %info_loss_of :ATTR( :get<info_loss> );

# method: get_category
# 


# method: get_name
# 


# method: get_starred
# 


# method: get_unstarred
# 

# method: get_info_loss
#

#
# subsection: Construction



# method: BUILD
# needs all four attributes
#

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $category_of{$id } = $opts_ref->{category}  or die "Need category";
    $meto_name_of{$id} = $opts_ref->{name}      or die "Need name";
    $starred_of{$id}   = $opts_ref->{starred}   or die "Need starred";
    $unstarred_of{$id} = $opts_ref->{unstarred} or die "Need unstarred";
    $info_loss_of{$id} = $opts_ref->{info_loss} or die "Need info_loss";

    weaken $unstarred_of{$id};
}

#
# subsection: Public interface



# method: intersection
# Given a bunch of Metonyms, returns a MetonymType object.
#

sub intersection{
    my ( $package, @meto ) = @_;
    @meto or die "Cannot take intersection of empty set";

    my $id_of_first = ident $meto[0];
    
    my $cat        = $category_of{$id_of_first};
    my $name       = $meto_name_of{$id_of_first};
    my $info_loss  = $info_loss_of{$id_of_first};
    my $loss_count = scalar(keys %$info_loss);

    for my $idx (1..$#meto) {
        my $id = ident $meto[$idx];

        # compare that this meto has the same "type"
        ($category_of{$id} eq $cat) 
            or return;
        ($meto_name_of{$id} eq $name)
            or return;

        # xxx: info loss assumption: values are simple.
        my $loss = $info_loss_of{$id};

        # make sure that the same number of things are lost
        (scalar(keys %$loss) == $loss_count)
            or return;

        # make sure that the lost things are the same
        while (my($k, $v) = each %$info_loss) {
            $loss->{$k} eq $v or return;
        }
    }
    
    return SMetonymType->new({ category  => $cat,
                               name      => $name,
                               info_loss => $info_loss,
                           });
}



# method: get_type
# Returns a MetonymType object corresponding to this Metonym
#
sub get_type{
    my ( $self ) = @_;
    SMetonym->intersection( $self );
}



1;

#####################################################
#
#    Package: SCat::OfCat
#
#####################################################
#   Categories whose nstances are categories.
#    
#   Examples include literals, and also things like "2 element group, the first of which is ascending, the second a mountain"
#####################################################

package SCat::OfCat;
use strict;
use Carp;
use Class::Std;
use base qw{SInstance};


# variable: %name_of
#    All categories need a name
my %name_of :ATTR( :get<name> );

# No instancer needed: a universal one will be used.

# variable: %builder_of
#    Builds a category
my %builder_of :ATTR( );

# In principle, these categories should also supoort metonymy and such, but I shall wait on that one.

#
# subsection: Constructor


# method: BUILD
# Builds a SCat::OfCat object
#
#    Just need the builder and the name, for now, I think
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;

    $name_of{$id} = $opts_ref->{name} or confess "Need name";
    $builder_of{$id} = $opts_ref->{builder}
        or confess "Need builder";
}



#
# subsection: Public Interface


# method: is_instance
# is this other category instance of this? 
#
#    It works simply: uses is_of_category_p
sub is_instance{
    my ( $self, $other ) = @_;
    return $other->is_of_category_p( $self );
}



# method: build
# Build an instance of an instance of SCat::OfCat
#
#    Just calls the builder_of
sub build{
    my ( $self, $opts_ref ) = @_;
    my $ret = $builder_of{ident $self}->( $self, $opts_ref );
    $S::Str2Cat{$ret} = $ret;
    return $ret;
}

1;



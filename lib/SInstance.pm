#####################################################
#
#    Package: SInstance
#
#####################################################
#   Manages objects that can belong to categories (or have properties)
#    
#   I am making drastic changes here. Now it will remember not just memberships in categories, but non memberships.
#####################################################

package SInstance;
use strict;
use Carp;
use Class::Std;
use base qw{};


# variable: %cats_of_of
#    Remembers category memberships. Keys are categories, values are SBindings objects.
my %cats_of_of : ATTR( :get<cats_hash> );


# variable: %non_cats_of_of
#    Remembers non memberships. Also the era when it was so seen (as it may be reversed later!)
my %non_cats_of_of :ATTR();


# variable: %property_of_of
#    Remembers attributes about objects
#     
#    Keys are strings, values are whatever
my %property_of_of :ATTR();



# method: BUILD
# Builder.
#
# Called automatically by new() of derivative classes
#
#    Should just set up the variables



sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $cats_of_of{ $id }     = {};
    $non_cats_of_of{ $id } = {};
    $property_of_of{$id}   = {};
}



# method: add_category
# Adds a category to a given object.
#
#    * If the category is already present, it is overwritten.
#    * If it is present as a non-category, that info is erased.
#     
#    Parameters:
#      $self - The object
#      $cat - The category
#      $bindings - SBindings specifying how the object is an instance of the category.

sub add_category{
    my ( $self, $cat, $bindings ) = @_;
    
    my $id = ident $self;
    
    $bindings->isa("SBinding") or die "Need SBinding";
    $cat->isa("SCat")          or die "Need SCat";

    my $cat_ref        = $cats_of_of{$id};
    my $non_cat_ref    = $non_cats_of_of{$id};

    if (exists $non_cat_ref->{$cat}) {
        delete $non_cat_ref->{$cat};
    }

    $cat_ref->{$cat} = $bindings;

}

# sub add_cat {
#     ( @_ == 3 ) or croak "add cat requires three args";
#     my ( $self, $cat, $bindings ) = @_;
#     UNIVERSAL::isa( $cat, "SCat" )
#         or croak "cat passed to add_cat ain't a cat";

#     foreach ( keys %$bindings ) {
#         $cat->has_attribute($_) or croak "$cat doesn't have attribute $_";
#     }
#     $SCat::Str2Cat{$cat} = $cat;
#     $cats_of_of{ ident $self}{$cat} = $bindings;
#     return $self;
# }



# method: add_non_category
# Specifies that this object is not of this category
#
#  If it is already a member of that category, nothing happens.
#
#    TODO:
#      * Should remember the time this was set.
#     
#    Parameters:
#    $self - object
#    $cat - the category it does not belong to

sub add_non_category {
    my ( $self, $cat ) = @_;
    my $id = ident $self;
    
    return if exists $cats_of_of{$id}{$cat};

    $non_cats_of_of{$id}{$cat} = 1; #XXX needs change
}



# method: add_property
# adds a property to an object
#
#    Parameters:
#    $self - the object
#    $property - the property
#    $value - the value of the property

sub add_property{
    my ( $self, $property, $value ) = @_;
    my $id = ident $self;

    $property_of_of{$id}{$property} = $value;

}



# method: is_of_category_p
# Given a category, says if the object belongs to that category
#
#    Parameters:
#    $self - the object
#    $cat - the category
#     
#    Returns:
#    Returns an array ref, as follows.
#     
#    if known to be instance - [1, Binding]
#    if known to not be an instance - [ 0, time of decision]
#    unknown - [undef]

sub is_of_category_p{
    my ( $self, $cat ) = @_;
    my $id = ident $self;

    if (exists $cats_of_of{$id}{$cat}) {
        return [1, $cats_of_of{$id}{$cat}];
    } elsif (exists $non_cats_of_of{$id}{$cat}) {
        return [0, $non_cats_of_of{$id}{$cat}];
    } else {
        return [undef];
    }
}

#
# section: leftover from earlier implementation
# Will update later

sub get_cat_bindings {
    my ( $self, $cat ) = @_;
    return unless exists $cats_of_of{ ident $self}{$cat};
    return $cats_of_of{ ident $self}{$cat};
}

sub get_cats {
    my $self = shift;
    return map { $SCat::Str2Cat{$_} } keys %{ $cats_of_of{ ident $self} };
}

sub get_blemish_cats {
    my $self = shift;
    my %ret;
    while ( my ( $k, $binding ) = each %{ $cats_of_of{ ident $self} } ) {
        if ( $SCat::Str2Cat{$k}->is_blemished_cat ) {
            $ret{$k} = $binding->{what};
        }
    }
    return \%ret;
}

sub instance_of_cat {
    my ( $self, $cat ) = @_;
    UNIVERSAL::isa( $cat, "SCat" ) or croak "Need SCat";
    return exists $cats_of_of{ ident $self}{$cat};
}

sub get_common_categories{
    my ( $o1, $o2 ) = @_;
    ### $o1, $o2
    my $hash_ref1 = $cats_of_of{ident $o1};
    my $hash_ref2 = $cats_of_of{ident $o2};
    ### $hash_ref1, $hash_ref2
    my @common_strings
        = grep { defined $_ } map { exists($hash_ref2->{$_}) ? $_ : undef  } keys %$hash_ref1;
    ### @common_strings
    return map { $SCat::Str2Cat{$_} } @common_strings;
}

1;

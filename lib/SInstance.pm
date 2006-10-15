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
use Smart::Comments;
use base qw{};

# variable: %cats_of_of
#    Remembers category memberships. Keys are categories, values are SBindings objects.
my %cats_of_of : ATTR( :get<cats_hash> );

# variable: %non_cats_of_of
#    Remembers non memberships. Also the era when it was so seen (as it may be reversed later!)
my %non_cats_of_of : ATTR();

# variable: %property_of_of
#    Remembers attributes about objects
#
#    Keys are strings, values are whatever
my %property_of_of : ATTR();

#
# subsection: Creation

# method: BUILD
# Builder.
#
# Called automatically by new() of derivative classes
#
#    Should just set up the variables

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $cats_of_of{$id}     = {};
    $non_cats_of_of{$id} = {};
    $property_of_of{$id} = {};
}

#
# subsection: Managing Categories

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

sub add_category {
    my ( $self, $cat, $bindings ) = @_;

    my $id = ident $self;

    $bindings->isa("SBindings") or die "Need SBinding";
    $cat->isa("SCat::OfObj")    or die "Need SCat";

    my $cat_ref     = $cats_of_of{$id};
    my $non_cat_ref = $non_cats_of_of{$id};

    if ( exists $non_cat_ref->{$cat} ) {
        delete $non_cat_ref->{$cat};
    }

    $self->add_history( "Added category " . $cat->get_name );

    # make string to object mapping
    $S::Str2Cat{$cat} = $cat;

    $cat_ref->{$cat} = $bindings;

}

sub remove_category {
    my ( $self, $cat ) = @_;

    my $id = ident $self;
    $cat->isa("SCat::OfObj") or die "Need SCat";

    my $cat_ref     = $cats_of_of{$id};
    my $non_cat_ref = $non_cats_of_of{$id};

    if ( exists $cat_ref->{$cat} ) {
        $self->add_history( "Removed category " . $cat->get_name );
        delete $cat_ref->{$cat};
    }

    # make string to object mapping
    $S::Str2Cat{$cat} = $cat;

    $non_cat_ref->{$cat} = 1;

}

# sub add_cat {
#     ( @_ == 3 ) or croak "add cat requires three args";
#     my ( $self, $cat, $bindings ) = @_;
#     UNIVERSAL::isa( $cat, "SCat" )
#         or croak "cat passed to add_cat ain't a cat";

#     foreach ( keys %$bindings ) {
#         $cat->has_attribute($_) or croak "$cat doesn't have attribute $_";
#     }
#     $S::Str2Cat{$cat} = $cat;
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

    $non_cats_of_of{$id}{$cat} = 1;    #XXX needs change
}

# method: add_property
# adds a property to an object
#
#    Parameters:
#    $self - the object
#    $property - the property
#    $value - the value of the property

sub add_property {
    my ( $self, $property, $value ) = @_;
    my $id = ident $self;

    $property_of_of{$id}{$property} = $value;

}

# method: get_categories
# Returns an array ref of categories this belongs to
#

sub get_categories {
    my ($self)      = @_;
    my $id          = ident $self;
    my @cat_strings = keys %{ $cats_of_of{$id} };
    return [] unless @cat_strings;
    return [ map { $S::Str2Cat{$_} } @cat_strings ];
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

sub is_of_category_p {
    my ( $self, $cat ) = @_;
    my $id = ident $self;

    if ( exists $cats_of_of{$id}{$cat} ) {
        return [ 1, $cats_of_of{$id}{$cat} ];
    }
    elsif ( exists $non_cats_of_of{$id}{$cat} ) {
        return [ 0, $non_cats_of_of{$id}{$cat} ];
    }
    else {
        return [undef];
    }
}

# method: get_binding
# Returns binding for a particular category
#

sub get_binding {
    my ( $self, $cat ) = @_;
    my $id = ident $self;

    return unless exists $cats_of_of{$id}{$cat};
    return $cats_of_of{$id}{$cat};
}

# method: inherit_categories_from
# copies category, non-category and property information from another object
#

sub inherit_categories_from {
    my ( $self, $other ) = @_;
    my $self_id  = ident $self;
    my $other_id = ident $other;

    my $cats_ref = $cats_of_of{$self_id};
    while ( my ( $k, $v ) = each %{ $cats_of_of{$other_id} } ) {
        $cats_ref->{$k} = seq_clone($v);
    }

    my $non_cats_ref = $non_cats_of_of{$self_id};
    while ( my ( $k, $v ) = each %{ $non_cats_of_of{$other_id} } ) {
        $non_cats_ref->{$k} = seq_clone($v);
    }

    my $prop_ref = $property_of_of{$self_id};
    while ( my ( $k, $v ) = each %{ $property_of_of{$other_id} } ) {
        $prop_ref->{$k} = seq_clone($v);
    }

}

#
# SubSection: Testing Methods

# method: is_of_category_ok
# Is the thing of the said category?
#
sub is_of_category_ok {
    my ( $self, $cat ) = @_;
    my $ret_ref = $self->is_of_category_p($cat);
    Test::More::ok( $ret_ref->[0] );
}

# method: get_common_categories
# Returns a list of categories shared by both
#

sub get_common_categories {
    my ( $o1, $o2 ) = @_;
    ## $o1, $o2
    my $hash_ref1 = $cats_of_of{ ident $o1};
    my $hash_ref2 = $cats_of_of{ ident $o2};
    ## $hash_ref1, $hash_ref2
    my @common_strings
        = grep { defined $_ } map { exists( $hash_ref2->{$_} ) ? $_ : undef } keys %$hash_ref1;
    ## @common_strings
    return map { $S::Str2Cat{$_} } @common_strings;
}

#
# subsection: leftover from earlier implementation
# Will update later

sub get_cat_bindings {
    my ( $self, $cat ) = @_;
    return unless exists $cats_of_of{ ident $self}{$cat};
    return $cats_of_of{ ident $self}{$cat};
}

sub get_cats {
    my $self        = shift;
    my $id          = ident $self;
    my @cat_strings = keys %{ $cats_of_of{$id} };
    return [] unless @cat_strings;
    return [ map { $S::Str2Cat{$_} } @cat_strings ];
}

sub get_blemish_cats {
    my $self = shift;
    my %ret;
    while ( my ( $k, $binding ) = each %{ $cats_of_of{ ident $self} } ) {
        if ( $S::Str2Cat{$k}->is_blemished_cat ) {
            $ret{$k} = $binding->{what};
        }
    }
    return \%ret;
}

sub instance_of_cat {
    my ( $self, $cat ) = @_;
    UNIVERSAL::isa( $cat, "SCat::OfObj" ) or confess "Need SCat";
    return exists $cats_of_of{ ident $self}{$cat};
}

sub categories_as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    my $list = new SInsertList;

    $list->append( "Categories: ", "heading2", "\n" );
    while ( my ( $c, $bindings ) = each %{ $cats_of_of{$id} } ) {
        my $cat = $S::Str2Cat{$c};
        $list->concat( $cat->as_insertlist(0)->indent(1) );
        if ( $verbosity > 0 ) {
            $list->concat( $bindings->as_insertlist( $verbosity )->indent(2) );
        }
    }

    $list->append( "Non Categories: ", "heading2", "\n" );
    while ( my ( $c, $bindings ) = each %{ $non_cats_of_of{$id} } ) {
        my $cat = $S::Str2Cat{$c};
        $list->concat( $cat->as_insertlist(0)->indent(1) );
    }

    # $list->append( "Properties: ", "heading2", "\n  Not currently used\n" );

    return $list;
}

1;


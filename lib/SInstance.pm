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

my %cats_of_of : ATTR( :get<cats_hash> );    # Keys categories, values bindings.

# Called automatically by new() of derivative classes
sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $cats_of_of{$id}     = {};
}

#
# subsection: Managing Categories

# method: add_category
# Adds a category to a given object.
#
#    * If the category is already present, it is overwritten.
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

    $self->AddHistory( "Added category " . $cat->get_name );

    # make string to object mapping
    $S::Str2Cat{$cat} = $cat;

    $cat_ref->{$cat} = $bindings;
}

sub remove_category {
    my ( $self, $cat ) = @_;

    my $id = ident $self;
    $cat->isa("SCat::OfObj") or die "Need SCat";

    my $cat_ref     = $cats_of_of{$id};

    if ( exists $cat_ref->{$cat} ) {
        $self->AddHistory( "Removed category " . $cat->get_name );
        delete $cat_ref->{$cat};
    }

    # make string to object mapping
    $S::Str2Cat{$cat} = $cat;
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
    else {
        return [undef];
    }
}

# method: GetBindingForCategory
# Returns binding for a particular category
#

sub GetBindingForCategory {
    my ( $self, $cat ) = @_;
    my $id = ident $self;

    return unless exists $cats_of_of{$id}{$cat};
    return $cats_of_of{$id}{$cat};
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

sub categories_as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    my $list = new SInsertList;

    $list->append( "Categories: ", "heading2", "\n" );
    while ( my ( $c, $bindings ) = each %{ $cats_of_of{$id} } ) {
        my $cat = $S::Str2Cat{$c};
        $list->concat( $cat->as_insertlist(0)->indent(1) );
        if ( $verbosity > 0 ) {
            $list->concat( $bindings->as_insertlist($verbosity)->indent(2) );
        }
    }

    return $list;
}

sub HasNonAdHocCategory {
    my ( $item ) = @_;
    for (keys %{$cats_of_of{ident $item}}) {
        return 1 unless $_ =~ m#ad_hoc_#;
    }
    return 0;
}


1;


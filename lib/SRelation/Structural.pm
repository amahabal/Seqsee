package SRelation::Structural;
use 5.10.0;
use strict;
use Class::Std;

use base qw{SRelation};
my %unchanged_bindings_of :ATTR(:name<unchanged_bindings>);

sub SuggestCategoryForEnds {
    my ( $self ) = @_;
    my $id = ident $self;

    my $assuming;
    my $cat = $self->get_category;

    my %unchanged_bindings = %{$unchanged_bindings_of{$id}};
    if (%unchanged_bindings) {
        $assuming = SCat::OfObj::Assuming->Create($cat, \%unchanged_bindings);
    } else {
        $assuming = $cat;
    }

    return $assuming;
}

sub SuggestCategory {
    my ( $self ) = @_;
    return SCat::OfObj::RelationTypeBased->Create($self->get_type);
}

1;

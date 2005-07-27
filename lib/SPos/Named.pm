package SPos::Named;
use strict;
use Carp;
use base "SPos";

use Class::Std;
my %name_of : ATTR( :set<name> :get<name> );
my %find_by_cat_of_of : ATTR;

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $name_of{$id} = $opts->{str} || croak "Need str!";
    $find_by_cat_of_of{$id} = {};
}

sub install_finder {
    my ( $self, %opts ) = @_;
    my $cat    = $opts{cat};
    my $finder = $opts{finder};
    $find_by_cat_of_of{ ident $self}{$cat} = $finder;

    # print "########## FOR ", ident $self," set finder for $cat\n";
}

sub find_range {
    my ( $self, $built_obj ) = @_;
    my $id = ident $self;

    # use Smart::Comments;
    ### self: $id
    my @cats = $built_obj->get_cats;
    ### cats: @cats
    my @matching_cats = grep { exists $find_by_cat_of_of{$id}{$_} } @cats;
    ### Matching cats for peak finding: @matching_cats
    return undef unless @matching_cats;
    my @matching_ranges =
        map { $find_by_cat_of_of{$id}{$_}->find_range($built_obj); }
        @matching_cats;
    ### Matching ranges for peak finding: @matching_ranges
    return $matching_ranges[0] if @matching_ranges == 1;

    # XXX I should check whether the different answers are the same,
    #  but right now I think I'll just throw..
    SErr::Pos::MultipleNamed->throw("$name_of{$id} for $built_obj");
}

1;

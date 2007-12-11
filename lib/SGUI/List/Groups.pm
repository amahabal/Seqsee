package SGUI::List::Groups;
use strict;
our @ISA = qw{SGUI::List};

sub new {
    my ( $package ) = @_;
    my $self = bless { strength_x => 0, 
                       ends_x => 50,
                       categories_x => 140,
                       Font => '-adobe-helvetica-bold-r-normal--9-140-100-100-p-105-iso8859-4',
                       HeightPerRow => 15,
                   }, $package;
    return $self;
}


sub GetItemList {
    return SWorkspace->GetGroups();
}

sub DrawOneItem {
    my ( $self, $Canvas, $left, $top, $group ) = @_;
    $Canvas->createText(
        $self->{EffectiveXOffset} + $self->{strength_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => sprintf( "%5.2f", $group->get_strength() ),
        -tags => [$self],
    );
    $Canvas->createText(
        $self->{EffectiveXOffset} + $self->{ends_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => $group->get_bounds_string(),
        -tags => [$self],
    );

    my $categories_string = $group->get_categories_as_string();
    $Canvas->createText(
        $self->{EffectiveXOffset} + $self->{categories_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => $categories_string,
        -tags => [$self],
    );
}

sub Clear {
    my ( $self ) = @_;
    $self->{Canvas}->delete($self);
}


1;

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

    $self->{ActionButtons} = {
        Delete => sub  {
            my ( $group ) = @_;
            SWorkspace::__DeleteGroup($group);
        }
            };
    return $self;
}


sub GetItemList {
    return SWorkspace->GetGroups();
}

sub DrawOneItem {
    my ( $self, $Canvas, $left, $top, $group ) = @_;
    my @item_ids;
    push @item_ids, $Canvas->createText(
        $left + $self->{strength_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => sprintf( "%5.2f", $group->get_strength() ),
        # -tags => [$self],
    );
    push @item_ids, $Canvas->createText(
        $left + $self->{ends_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => $group->get_bounds_string(),
        # -tags => [$self],
    );

    my $categories_string = $group->get_categories_as_string();
    push @item_ids, $Canvas->createText(
        $left + $self->{categories_x}, $top,
        -anchor => 'nw',
        -font   => $self->{Font},
        -text   => $categories_string,
        # -tags => [$self],
    );
    return @item_ids;
}

1;

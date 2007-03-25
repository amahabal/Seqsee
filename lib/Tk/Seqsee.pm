package Tk::Seqsee;
use strict;
use warnings;
use Carp;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);
use base qw/Tk::Derived Tk::Frame/;

use Themes::Std;
use SGUI::Workspace;
use SGUI::Slipnet;
use SGUI::Categories;

my $Canvas;
my ( $Width, $Height );
Construct Tk::Widget 'Seqsee';

my @ViewOptions = (
    ['Workspace', [['SGUI::Workspace', 0, 0, 100, 100]]],
    ['Workspace + Slipnet', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Slipnet', 0, 50, 100, 50 ],
            ]],
    ['Workspace + Categories', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Categories', 0, 50, 100, 50 ],
            ]],
        );

my @Parts = @{ $ViewOptions[0][1] };

sub SetupParts {
    for my $part (@Parts) {
        my ( $package, $l, $t, $w, $h ) = @$part;
        $package->Setup(
            $Canvas,
            $l * 0.01 * $Width,
            $t * 0.01 * $Height,
            $w * 0.01 * $Width,
            $h * 0.01 * $Height
        );
    }
}

sub Update {
    $Canvas->delete('all');
    $_->[0]->DrawIt() for @Parts;
}

sub Populate {
    my ( $self, $args ) = @_;
    my $l_Menubar = $self->Menustrip();

    $l_Menubar->MenuLabel('View');
    for my $vo (@ViewOptions) {
        $l_Menubar->MenuEntry( 'View', $vo->[0],
                               sub {
                                   @Parts = @{$vo->[1]};
                                   SetupParts();
                                   Update();
                               }
                                   );
    }

    $l_Menubar->MenuLabel( 'Help', '-right' );
    $l_Menubar->MenuEntry( 'Help', 'About...' );
    $l_Menubar->MenuSeparator('Help');
    $l_Menubar->MenuEntry( 'Help', 'Help On...' );

    $l_Menubar->pack( -fill => 'x' );
    ( $Height, $Width ) =
      ( $args->{'-height'}, $args->{'-width'} );
    $Canvas = $self->Canvas( -height => $Height,
                             -width => $Width)->pack( -side => 'bottom' );
    SetupParts();
}

1;

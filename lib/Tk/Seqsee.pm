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

use Themes::Std2;
use SGUI::Workspace;
use SGUI::Slipnet;
use SGUI::Categories;
use SGUI::Stream;
use SGUI::Coderack;

my $Canvas;
my ( $Width, $Height );
Construct Tk::Widget 'Seqsee';

my @ViewOptions = (
    ['Workspace + Stream', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Stream', 0, 50, 100, 50 ],
            ]],
    ['Workspace', [['SGUI::Workspace', 0, 0, 100, 100]]],
    ['Workspace + Slipnet', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Slipnet', 0, 50, 100, 50 ],
            ]],
    ['Workspace + Categories', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Categories', 0, 50, 100, 50 ],
            ]],
    ['Workspace + Coderack', [
        [ 'SGUI::Workspace',  0, 0,  100, 50 ],
        [ 'SGUI::Coderack', 0, 50, 100, 50 ],
            ]],
        );

my @Parts = @{ $ViewOptions[$Global::Options_ref->{view}||0][1] };

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

{
my $AttentionNeeded = 0;

sub AttentionNeeded {
    $AttentionNeeded = 1;
}

sub AttentionNoLongerNeeded {
    $AttentionNeeded = 0;
}



sub Update {
    $Canvas->delete('all');
    $_->[0]->DrawIt() for @Parts;
    DrawAttentionDirectingArrows() if $AttentionNeeded;
}


sub DrawAttentionDirectingArrows {
    my $arrow_top = 0.92 * $Height;
    my $arrow_bottom = 0.99 * $Height;

    for (5) {
        my $x_top = $Width * $_ / 10;
        my $x_bottom = $Width * (0 + $_ / 10 );
        $Canvas->createLine($x_top, $arrow_top, $x_bottom, $arrow_bottom,
                            -arrow => 'last',
                            -width => 15,
                            -fill => '#FF0000',
                                );
    }
    $Canvas->createText($Width * 0.5, $Height * 0.88,
                        -text => 'PLEASE SEE BELOW',
                        -anchor => 'n',
                        Style::Element(),
                        -fill => '#FF0000',
                            );
}
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

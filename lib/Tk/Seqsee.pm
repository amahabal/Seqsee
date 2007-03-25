package Tk::Seqsee;
use strict;
use warnings;
use Carp;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);
use base qw/Tk::Derived Tk::Canvas/;

use Themes::Std;
use SGUI::Workspace;
use SGUI::Slipnet;
use SGUI::Categories;

my $Canvas;
my ( $Width, $Height );
Construct Tk::Widget 'Seqsee';

my @Parts = ( [ 'SGUI::Workspace', 0, 0, 100, 50 ],
              [ 'SGUI::Categories', 0, 50, 100, 50],
                  );

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

sub Populate{
    my ( $self, $args ) = @_;
     ( $Canvas, $Height, $Width ) =
         ( $self, $args->{'-height'}, $args->{'-width'} );
    SetupParts();
}

1;

package Style;
use Carp;

sub AUTOLOAD {
    our $AUTOLOAD;
    confess "Unknown method $AUTOLOAD called. Have you defined this style?";
}

package Themes::Std;
use Memoize;
use SColor;
use Carp;

*HSV = \&SColor::HSV2Color;

STYLE Element( $hilit ! ) is {
font: {
        $hilit
            ? '-adobe-helvetica-bold-r-normal--28-140-100-100-p-105-iso8859-4'
            : '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4';
    }
anchor: {'center'}
fill: {
        if ( $hilit == 1 ) {
            '#00FF00';
        }
        elsif ( $hilit == 2 ) {
            '#0000FF';
        }
        else {
            HSV( 160, 20, 20 );
        }
    }
}

STYLE Starred() is {
font: {'-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'}
anchor: {'center'}
fill: { HSV( 240, 50, 50 ) }
}

STYLE Relation( $strength !, $hilit ! ) is {
arrow: {'last'}
width: { $hilit ? 5 : 3 }
fill: { $hilit ? "#00FF00" : HSV( 60, 40, 80 - 0.5 * $strength ) }
smooth: {1}
}

STYLE Group( $meto !, $strength !, $is_largest ! ) is {
fill: {
        my ( $s, $v ) = ( 40, 90 - 0.4 * $strength );
        $meto ? HSV( 240 - 20 * $is_largest, $s, $v ) : HSV( 160 - 20 * $is_largest, $s, $v );
    }
width: {0}
}

STYLE GroupBorder( $hilit ! ) is {
outline: {
        if ( $hilit == 1 ) {
            '#00FF00';
        }
        elsif ( $hilit == 2 ) {
            '#0000FF';
        }
        else { HSV( 240, 70, 70 ) }
    }
width: { 2 + 2 * $hilit }
}

STYLE ElementAttention( $attention ! ) is {
fill: {
        my ( $s, $v ) = ( 40, 400 * $attention );
        $v = 0 if $v < 0;
        $v = 99 if $v > 99;
        HSV( 300, $s, $v );
    }
font: {
        '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4';
    }
}

STYLE GroupAttention( $attention ! ) is {
fill: {
        my ( $s, $v ) = ( 40, 400 * $attention );
        $v = 0 if $v < 0;
        $v = 99 if $v > 99;
        HSV( 160, $s, $v );
    }
}

STYLE GroupBorderAttention() is {
  outline: { HSV(180, 40, 5 )}
}

STYLE RelationAttention( $attention ! ) is {
fill: {
        my ( $s, $v ) = ( 40, 400 * $attention );
        $v = 0 if $v < 0;
        $v = 99 if $v > 99;
        HSV( 190, $s, $v );
    }
arrow: {'last'}
width: { 4 }
smooth: {1}
}

STYLE NetActivation( $raw_significance ! ) is {
fill: { HSV( 240, 30, 90 - 0.88 * $raw_significance ) }
}

STYLE ThoughtBox( $hit_intensity !, $is_current ! ) is {
fill: {
        $hit_intensity = 2000 if $hit_intensity > 2000;
        my ( $s, $v ) = ( 40, 90 - 0.02 * $hit_intensity );

        # print "$hit_intensity => $v\n";
        $is_current ? HSV( 120, $s, $v ) : HSV( 100, $s, $v );
    }
width: {
        $is_current ? 3 : 1;
    }
}

STYLE ThoughtComponent( $presence_level !, $component_importance ! ) is {
fill: {

        # my ( $s, $v ) = ( 90, 80 - 0.5 * $component_importance );
        # my ( $s, $v ) = ( 90, 80 );
        # print "$component_importance => $v\n";
        HSV( 250, 90, 80 );
    }
font: {'-adobe-helvetica-bold-r-normal--10-140-100-100-p-105-iso8859-4'}
}

STYLE ThoughtHead() is {
font: {'-adobe-helvetica-bold-r-normal--14-140-100-100-p-105-iso8859-4'}
}

1;
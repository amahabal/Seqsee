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

STYLE Element() is {
font: {'-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'}
anchor: {'center'}
fill: { HSV( 160, 20, 20 ) }
}

STYLE Starred() is {
font: {'-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'}
anchor: {'center'}
fill: { HSV( 240, 50, 50 ) }
}

STYLE Relation( $strength ! ) is {
arrow: {'last'}
width: {3}
fill: { HSV( 60, 40, 80 - 0.5 * $strength ) }
smooth: {1}
}

STYLE Group( $meto !, $hilit !, $strength !, $is_largest ! ) is {
fill: {
        my ( $s, $v ) = ( 40, 80 - 0.5 * $strength );
        $meto ? HSV( 240 - 20 * $is_largest, $s, $v ) : HSV( 160 - 20 * $is_largest, $s, $v );
    }
width: {0}
}

STYLE GroupBorder( $meto !, $hilit !, $strength ! ) is {
outline: {
        my ( $s, $v ) = ( 50, 70 - 0.5 * $strength );
        if ($hilit) {
            '#FF0000';
        }
        else { $meto ? HSV( 240, $s, $v ) : HSV( 160, $s, $v ); }
    }
width: { 1 + 1 * $hilit }
}

STYLE NetActivation($raw_significance!) is {
fill: { HSV( 240, 30, 90 - 0.88 * $raw_significance ) }
}

STYLE ThoughtBox( $hit_intensity !, $is_current ! ) is {
fill: {
        $hit_intensity = 2000 if $hit_intensity > 2000;
        my ( $s, $v ) = ( 40, 80 - 0.025 * $hit_intensity );

        # print "$hit_intensity => $v\n";
        $is_current ? HSV( 120, $s, $v ) : HSV( 100, $s, $v );
    }
width: {
        $is_current ? 3 : 1;
    }
}

STYLE ThoughtComponent($presence_level!, $component_importance!) is {
  fill: {    my ($s, $v) = (70, 80 - 0.5 * $component_importance);
    print "$component_importance => $v\n";
    HSV(30, $s, $v)
}
}

STYLE ThoughtHead() is {
font: {'-adobe-helvetica-bold-r-normal--12-140-100-100-p-105-iso8859-4'}
}

1;

#####################################################
#
#    Package: SPos
#
#####################################################
#   Manages positions
#####################################################

package SPos;
use strict;
use Carp;
use SPos::Forward;
use SPos::Backward;

{
    my %MEMO;

    sub new {
        my ( $package, $what, $type ) = @_;
        confess unless $what =~ m/^ -? \d+ $/ox;
        unless ($type) {
            $type =
                  ( $what > 0 ) ? "Forward"
                : ( $what < 0 ) ? "Backward"
                :                 confess "SPos->new(0) illegal";
        }
        my $key = "$what;$type";
        return $MEMO{$key} ||= "SPos::$type"->new( { index => $what } );
    }
}

1;

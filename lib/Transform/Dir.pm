package Transform::Dir;
use 5.10.0;
use strict;

sub create {
    my ( $package, $string ) = @_;
    state %MEMO;
    return $MEMO{$string} ||= $package->new($string);
}

sub new {
    my ( $package, $string ) = @_;
    bless \$string, $package;
}

our $Same      = Transform::Dir->create('Same');
our $Different = Transform::Dir->create('Different');
our $Unknown   = Transform::Dir->create('Unknown');

multimethod FindTransform => qw(DIR DIR) => sub  {
    my ( $da, $db ) = @_;
    if ( $da eq DIR::RIGHT() ) {
        return ( $db eq DIR::RIGHT() ) ? $Same
            : ( $db  eq DIR::LEFT() )  ? $Different
            :                            $Unknown;
    }
    elsif ( $da eq DIR::LEFT() ) {
        return ( $db eq DIR::RIGHT() ) ? $Different
            : ( $db  eq DIR::LEFT() )  ? $Same
            :                            $Unknown;
    }
    else {
        return $Unknown;
    }
};

1;

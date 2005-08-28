package SReln;

use Class::Multimethods;
multimethod find_reln => qw(SBuiltObj SBuiltObj) =>
    sub {
        my ( $o1, $o2 ) = @_;
        return;
    };

1;

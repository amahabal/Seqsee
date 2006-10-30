#####################################################
#
#    Package: SCat::ascending
#
#####################################################
#   Sets up the category "ascending"
#####################################################

package SCat::ascending;
use strict;
use Carp;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    confess q{need start} unless exists $args_ref->{start};
    confess q{need end}   unless exists $args_ref->{end};

    my $ret = SObject->create( $args_ref->{start} .. $args_ref->{end} );
    $ret->add_category( $self, SBindings->create( {}, $args_ref, $ret ) );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
};

our $ascending = SCat::OfObj->new(
    {   name        => q{ascending},
        to_recreate => q{$S::ASCENDING},
        builder     => $builder,

        to_guess => [qw/start end/],
        att_type => {
            start => q{int},
            end   => q{int},
        },
        positions => {
            start => SPos->new(1),
            end   => SPos->new(-1),
        },
    }
);

1;


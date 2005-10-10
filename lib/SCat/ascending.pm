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
    croak "need start" unless $args_ref->{start};
    croak "need end"   unless $args_ref->{end};

    my $ret = SObject->create( $args_ref->{start} .. $args_ref->{end} );
    $ret->add_cat( $self, 
                   SBindings->create( [], $args_ref, $ret)
                       );
    return $ret;
};

our $ascending =
    SCat::OfObj->new(
        {
            name    => "ascending",
            builder => $builder,

            to_guess  => [qw/start end/],
            positions => { start => SPos->new(1),
                           end   => SPos->new(-1),
                       },
        }
            );

1;



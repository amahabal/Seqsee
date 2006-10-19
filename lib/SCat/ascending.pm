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
    confess "need start" unless exists $args_ref->{start};
    confess "need end"   unless exists $args_ref->{end};

    my $ret = SObject->create( $args_ref->{start} .. $args_ref->{end} );
    $ret->add_category( $self, 
                   SBindings->create( {}, $args_ref, $ret)
                       );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
};

our $ascending =
    SCat::OfObj->new(
        {
            name    => "ascending",
            builder => $builder,

            to_guess  => [qw/start end/],
            att_type  => { start => "int",
                           end => "int",
                       },
            positions => { start => SPos->new(1),
                           end   => SPos->new(-1),
                       },
        }
            );

1;



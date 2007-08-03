#####################################################
#
#    Package: SCat::descending
#
#####################################################
#   Sets up the category "descending"
#####################################################

package SCat::descending;
use strict;
use Carp;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    my $params_count;
    for (qw{start end length}) {
        $params_count++ if exists $args_ref->{$_};
    }
    confess 'Too few params' if $params_count < 2;
    my ($start, $end);
    $start = exists($args_ref->{start})?$args_ref->{start}: $args_ref->{end}+$args_ref->{length} - 1;
    $end = exists($args_ref->{end})?$args_ref->{end}: $args_ref->{start}-$args_ref->{length} + 1;
    $args_ref->{start} ||= $start; 
    $args_ref->{end} ||= $end;
    $args_ref->{length} ||= $start -$end + 1;

    my $ret = SObject->create( reverse( $args_ref->{end} .. $args_ref->{start} ) );
    $ret->add_category( $self, SBindings->create( {}, $args_ref, $ret ) );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
};

our $descending = SCat::OfObj->new(
    {   name        => q{descending},
        to_recreate => q{$S::DESCENDING},
        builder     => $builder,

        to_guess  => [qw/start end/],
        att_type  => { start => q{int}, end => q{int} },
        positions => {
            start => SPos->new(1),
            end   => SPos->new(-1),
        },
        sufficient_atts => {
            'end:start' => 1,
            'length:start' => 1,
            'end:length' => 1,
            'end:length:start' => 1, # stupid!!
        },
    }
);

1;


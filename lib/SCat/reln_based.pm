#####################################################
#
#    Package: SCat::reln_based
#
#####################################################
#####################################################

package SCat::reln_based;
use strict;
use Carp;
use Class::Std;
use base qw{};
use Class::Multimethods;
use Smart::Comments;

multimethod 'are_relns_compatible';

my $builder = sub {
    my ( $self ) = @_;
    confess "Should never be called!";
};

my $instancer = sub {
    my ( $self, $object ) = @_;
    my $reln = $object->get_underlying_reln;
    ## underlying_reln: $reln
    return unless $reln;

    my @parts = map { $_->get_effective_object } @{ $object->get_parts_ref };
    my $parts_count = scalar(@parts);

    for my $i (0 .. ($parts_count - 2)) {
        my $rel_between_parts = $parts[$i]->get_relation($parts[$i+1]);
        ## Relations: $rel_between_parts, $parts[$i], $parts[$i+1]
        return unless $rel_between_parts;
        return unless are_relns_compatible($reln, $rel_between_parts);
    }
    ## instancer accepted!

    my $slippages = {};
    @parts = @{ $object->get_parts_ref };
    for my $i (0 .. $parts_count - 1) {
        my $part = $parts[$i];
        if ($part->get_metonym_activeness) {
            my $metonym = $part->get_metonym;
            $slippages->{$i} = $metonym;
            ## $slippages->{$i}
        }
    }    

    # NOTE: relation is not an attribute because o/w we will need to see how
    # relations change. We may need other mechanisms.
    return SBindings->create( $slippages, { }, $object);
};

our $reln_based =
    SCat::OfObj->new({
        name => 'reln_based',
        builder => $builder,
        instancer => $instancer,
    });

1; 


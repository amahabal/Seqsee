#####################################################
#
#    Package: SCat::mountain
#
#####################################################
#   Sets up the category "mountain"
#####################################################

package SCat::mountain;
use strict;
use Carp;
use Class::Std;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    croak "need foot" unless $args_ref->{foot};
    croak "need peak" unless $args_ref->{peak};

    my $ret = SObject->create( $args_ref->{foot} .. $args_ref->{peak},
                               reverse($args_ref->{foot}.. $args_ref->{peak}-1)
                                   );
    $ret->add_category( $self,
                   SBindings->create( {}, $args_ref, $ret)
                       );
    return $ret;
};

my $peak_finder = sub {
    my ( $object ) = @_;
    my $item_count = $object->get_parts_count;
    return unless $item_count % 2;
    my $idx = ($item_count - 1) / 2;
    return $object->[$idx];
};


our $mountain =
    SCat::OfObj->new(
        {
            name    => "mountain",
            builder => $builder,

            to_guess  => [qw/foot peak/],
            positions => { foot => SPos->new(1),
                       },
            position_finders => { peak => $peak_finder },
        }
            );

1;


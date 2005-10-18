#####################################################
#
#    Package: SCat::sameness
#
#####################################################
#   Sets up the category "Sameness"
#####################################################

package SCat::sameness;
use strict;
use Carp;
use Class::Std;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    croak "need each" unless exists $args_ref->{each};
    croak "need length" unless exists $args_ref->{length};

    my @items = map { $args_ref->{each} } (1..$args_ref->{length});
    my $ret = SObject->create(@items);
    
    $ret->add_category( $self,
                   SBindings->create( {}, $args_ref, $ret),
                       );
    return $ret;

};

my $length_finder = sub {
    my ( $object, $name ) = @_;
    return $object->get_parts_count;
};

my $meto_finder_each = sub {
    my ( $object, $cat, $name, $bindings ) = @_;
    my $starred = $bindings->get_binding("each");
    my $info_lost = { length => $bindings->get_binding("length") };
    
    return SMetonym->new({
        category  => $cat,
        name      => $name,
        starred   => $starred,
        unstarred => $object,
        info_loss => $info_lost,
            });

};


our $sameness =
    SCat::OfObj->new(
        {
            name => "sameness",
            builder => $builder,
            
            to_guess => [qw/each length/],
            positions => { each => SPos->new(1) },
            description_finders => { length => $length_finder },

            metonymy_finders => { each => $meto_finder_each },

        }

            );

1;


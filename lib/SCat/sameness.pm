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

use Class::Multimethods 'find_reln';
use Smart::Comments;

my $first_pos = new SPos(1);

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    confess "need each" unless exists $args_ref->{each};
    confess "need length" unless exists $args_ref->{length};

    my @items = map { $args_ref->{each} } (1..$args_ref->{length});
    
    my $cnt = scalar(@items);
    ## $cnt

    my $ret = SObject->create(@items);

    $ret->add_category( $self,
                   SBindings->create( {}, $args_ref, $ret),
                       );

    # the next line affects things only while plonking this group
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );

    return $ret;

};

my $length_finder = sub {
    my ( $object, $name ) = @_;
    return $object->get_parts_count;
};

my $each_finder = sub {
    my ( $object, $name ) = @_;
    my $each = $object->get_at_position($first_pos);
    return $each;
    # return $S::LITERAL->build({ structure => $each->get_structure });
};

my $meto_finder_each = sub {
    my ( $object, $cat, $name, $bindings ) = @_;
    my $starred = $bindings->get_binding("each");
    my $info_lost = { length => $bindings->get_binding("length") };
    
    return SMetonym->new({
        category  => $cat,
        name      => $name,
        starred   => SAnchored->create( $starred ), 
        unstarred => $object,
        info_loss => $info_lost,
            });

};

my $meto_unfinder_each = sub {
    my ( $cat, $name, $info_loss, $object ) = @_;
    return $cat->build( { each => $object, %$info_loss });
};


our $sameness =
    SCat::OfObj->new(
        {
            name => "sameness",
            builder => $builder,
            
            to_guess => [qw/each length/],
            positions => {},
            description_finders => { length => $length_finder,
                                     each   => $each_finder,
                                 },

            metonymy_finders => { each => $meto_finder_each },
            metonymy_unfinders => { each => $meto_unfinder_each },
        }

            );

1;


#####################################################
#
#    Package: SCat::Number
#
#####################################################
#####################################################

package SCat::Number;
use strict;
use Carp;
use Class::Std;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    confess q{need mag} unless $args_ref->{mag};
    my $ret = SElement->create($args_ref->{mag}, -1);
    $ret->add_category($self, SBindings->create({}, $args_ref, $ret));

    return $ret;
};

my $instancer = sub {
    my ( $cat, $object ) = @_;
    return unless $object->isa('SElement');
    return SBindings->create({}, { mag => $object->get_mag() }, $object);
};

my $meto_finder_square = sub {
    my ( $object, $cat, $name, $bindings ) = @_;
    my $mag = $bindings->GetBindingForAttribute('mag');
    my $mag_sqrt = sqrt($mag);
    return unless int($mag_sqrt) == $mag_sqrt;
    my $starred = SElement->create($mag_sqrt, -1);
    return SMetonym->new({
        category => $cat,
        name => $name,
        starred => $starred,
        unstarred => $object,
        info_loss => {},
        info_gain => {},
    });
};

my $meto_unfinder_square = sub {
    my ( $cat, $name, $info_loss, $object ) = @_;
    my $mag = $object->get_mag();
    return $cat->build( { mag => $mag * $mag });
};

our $Number = SCat::OfObj->new({
    name => 'number',
    to_recreate => '$S::NUMBER',
    builder => $builder,
    instancer => $instancer,
    metonymy_finders => { square => $meto_finder_square},
    metonymy_unfinders => { square => $meto_unfinder_square},
});

1;




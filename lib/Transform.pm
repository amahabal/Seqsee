package Transform;
use 5.10.0;
use Class::Multimethods;
use strict;

multimethod FindTransform => ( '*', '*', '*' ) => sub {
    my ( $a, $b, $cat ) = @_;
    $cat->FindTransformForCat( $a, $b );
};

{
    my $numeric_FindTransorm = sub {
        my ( $a, $b ) = @_;
        my @common_categories = $a->get_common_categories($b) or confess;
        my $cat = SLTM::SpikeAndChoose( 0, @common_categories );
        $cat->FindTransformForCat( $a->get_mag(), $b->get_mag() );
    };
    multimethod FindTransform => qw{SInt SInt}         => $numeric_FindTransorm;
    multimethod FindTransform => qw{SElement SElement} => $numeric_FindTransorm;
}

multimethod FindTransform => qw(# #) => sub {
    my ( $a, $b ) = @_;
    $S::NUMBER->FindTransformForCat( $a, $b );
};

multimethod FindTransform => qw(SAnchored SAnchored) => sub {
    my ( $a, $b ) = @_;
    my @common_categories = $a->get_common_categories($b) or return;
    my $cat = SLTM::SpikeAndChoose( 0, @common_categories );
    $cat->FindTransformForCat( $a->get_mag(), $b->get_mag() );
};

# More FindTransform in Transform::Dir

multimethod ApplyTransform => qw(Transform::Numeric #) => sub  {
    my ( $transform, $num ) = @_;
    $transform->get_category()->ApplyTransformForCat($num);
};

multimethod ApplyTransform => qw(Transform::Numeric *) => sub  {
    my ( $transform, $num ) = @_;
    $transform->get_category()->ApplyTransformForCat($num->get_mag());
};

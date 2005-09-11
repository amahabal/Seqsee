package SWorkspace;
use strict;
use Class::Multimethods;

our $elements_count;
our @elements = ();

sub clear{
    $elements_count = 0;
    @elements       = ();
}

sub init {
    my ( $package, $OPTIONS_ref ) = @_;
    @elements       = ();
    $elements_count = 0;
    my @seq = @{ $OPTIONS_ref->{seq} };
    for ( @seq ) {
        # print "Inserting '$_'\n";
        _insert_element( $_ );
    }
}

sub insert_elements{
    shift;
    for (@_) {
        _insert_element( $_ );
    }
}

multimethod _insert_element => ( '#' ) => sub {
    _insert_element( SElement->new( { mag => shift } ) );
};

multimethod _insert_element => ( '$' ) => sub {
    use Scalar::Util qw(looks_like_number);
    my $what = shift;
    if (looks_like_number($what)) {
        _insert_element( SElement->new( { mag => shift } ) );
    } else {
        die "Huh? Trying to insert '$what' into the workspace";
    }
};

multimethod _insert_element => ( 'SElement') => sub {
    my $elt = shift;
    $elt->set_left_edge($elements_count);
    $elt->set_right_edge($elements_count);
    push( @elements, $elt );
    $elements_count++;
};

1;

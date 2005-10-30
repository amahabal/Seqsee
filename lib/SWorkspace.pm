#####################################################
#
#    Package: SWorkspace
#
#####################################################
#   manages the workspace
#####################################################

package SWorkspace;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{};

use Perl6::Form;

# Next 2 lines: should be my!
our $elements_count;
our @elements = ();


# variable: @OBJECTS
#    All groups and elements that are present
my @OBJECTS;

# variable: $ReadHead
#    Points just beyond the last object read.
#     
#    If never called before any reads, points to 0.
my $ReadHead = 0;


# method: clear
#  starts workspace off as new

sub clear{
    $elements_count = 0;
    @elements       = ();
}

# method: init
#   Given the options ref, initializes the workspace
#
# exceptions:
#   none

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

# section: _insert_element

# method: _insert_element(#)

# method: _insert_element($)

# method: _insert_element(SElement)

multimethod _insert_element => ( '#' ) => sub {
    _insert_element( SElement->create( shift ) );
};

multimethod _insert_element => ( '$' ) => sub {
    use Scalar::Util qw(looks_like_number);
    my $what = shift;
    if (looks_like_number($what)) {
        _insert_element( SElement->create( int( $what ) ) );
    } else {
        die "Huh? Trying to insert '$what' into the workspace";
    }
};

multimethod _insert_element => ( 'SElement') => sub {
    my $elt = shift;
    $elt->set_left_edge($elements_count);
    $elt->set_right_edge($elements_count);
    push( @elements, $elt );
    push( @OBJECTS, $elt );
    $elements_count++;
};



# method: read_object
# Don't yet know how this will work... right now just returns some object at the readhead and advances it.
#
sub read_object{
    my ( $package ) = @_;
    my $object = _get_some_object_at( $ReadHead );
    my $right_edge = $object->get_right_edge;
    
    if ($right_edge == $elements_count - 1 ) {
        _saccade();
    } else {
        $ReadHead = $right_edge + 1;
    }

    return $object;

}



# method: _get_some_object_at
# returns some object spanning that index.
#

sub _get_some_object_at{
    my ( $idx ) = @_;
    my @matching_objects = 
        grep { $_->get_left_edge() <= $idx and 
                   $_->get_right_edge() >= $idx
           } @OBJECTS;
    
    my $how_many = scalar( @matching_objects );
    return unless $how_many;
    return $matching_objects[ int( rand() * $how_many ) ];
}



# method: display_as_text
# prints a string desciption of what's in the workspace
#
sub display_as_text{
    my ( $package ) = @_;
    print form 
        "======================================================",
        " Elements:  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
        join(", ", map {$_->get_mag()} @elements),
        "======================================================";
    

}



# method: _saccade
# unthought through method to saccade
#
#    Jumps to a random valid position
sub _saccade{
    my $random_pos = int( rand() * $elements_count );
    $ReadHead = $random_pos;
}


1;

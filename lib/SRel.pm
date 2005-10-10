#####################################################
#
#    Package: SRel
#
#####################################################
#   Manages relations between objects.
#    
#   The nature of relations is very stroingly coupled with the nature of SBindings. My current thoughts look like what follows.
#    
#   Base Category:
#   A relation is based on both objects belonging to a category. For example, the relation between [1 2 3] and [1 2 3 4] is based on the category "ascending". Maybe this is a blunder on my part: While triangle and square are so related (by the category "Polygon"), Bloomington and Indiana do not share such a category directly. Maybe there is a large range of things in Seqsee domain of the Bloomington-Indiana type. When [2 2 2] is seen as a 2, it is an event of this type, perhaps. I am not calling that a relation, but rather a metonym, but maybe that too is a blunder. But Let me carry on with this figment for now.
#    
#   Base Metonymy Mode:
#   If two objects are to have a relation, I'd like them to have the same metonymy mode: No blemish, a single blemish or everything blemished.
#    
#   Base Position Mode:
#   They should also share the same way of looking at positions. See SBindings for details.
#    
#   Unchanged Bindings
#   A hashref of what bindings stayed put. Keys are binding keys, values are binding values (e.g., length => 3)
#    
#   Changed Bindings:
#   A hashref of what bindings changed, and how. E.g., start => successor
#    
#   Position:
#   Indicates what happened to the position. Could indicate a change or "same"
#    
#   Unstarred Relation:
#   If there is a single metonymy involved, this indicates the relation between the unstarred versions.
#    
#   Starred Relation:
#   as above. But what happens when the metonymy_mode is "ALL" I do not yet know.
#####################################################

package SRel;
use strict;
use Carp;
use Class::Std;
use base qw{SInstance };


# 
# subsection: Defunct Stuff


# variable: %first_of
#    Ref to the first of the two objects. 
#     
#    Does not necessarily mean the left object.
my %first_of : ATTR( :get<first> );


# variable: %second_of
#    Ref to the second
my %second_of : ATTR ( :get<second> );



# method: get_both
# Returns both the objects

sub get_both{
    my $self = shift;
    my $ident = ident $self;
    return ( $first_of{$ident}, $second_of{$ident} );
}



# method: BUILD
# builds
#
#    Would surely need to be modified. Changes needed:
#    * weaken refs
#    * Memoize in some intelligent way
#    * make these remembered by objects.

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $first_of{$id}   = $opts_ref->{first}  or die "Need first";
    $second_of{$id}  = $opts_ref->{second} or die "Need second";
}

1;

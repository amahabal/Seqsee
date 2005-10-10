#####################################################
#
#    Package: SCat::OfObj
#
#####################################################
#   Categories whose instances are objects
#
#   This package implements categories whose instances are Objects. Examples of such categories include Ascending, descending, sameness and mountain, plus, of course their derivatives.
#
#####################################################
#
# Positions:
#  These categories have the concept of positions defined for them.

package SCat::OfObj;
use strict;
use Carp;
use Class::Std;
use base qw{ SCat};


# variable: %instancer_of
#    functions called by is_instance
my %instancer_of :ATTR;


# variable: %builder_of
#    buider


# variable: %positions_of_of
#    positions (e.g, foot => SPos(1))
my %positions_of_of :ATTR;

# variable: %position_finders_of_of
#    positions, but as subs (e.g., peak => sub {})
my %position_finders_of_of :ATTR;

# variable: %description_finders_of_of
#    subs. (e.g., height => sub {})
my %description_finders_of_of :ATTR;

# variable: %atts_to_be_guessed_of
#    array ref of attributes that need guessing
my %atts_to_be_guessed_of :ATTR;


# variable: %guesser_of_of
#    for subroutines to guess
my %guesser_of_of :ATTR;

#
# subsection: The public interface

# multi: is_instance ( SCat::OfObj, SObject )
#  for object categories
#  
#    return value:
#      An SBindings object
#
#    possible exceptions:
#        SErr::Think

use Class::Multimethods;
multimethod is_instance => qw(SCat::OfObj SObject) => sub {
    my ( $cat, $object ) = @_;
    return $instancer_of{ ident $cat}->( $cat, $object );
};




# method: build
# builds an instance of the category
#
#    Takes a single hashref of parameters
sub build{
    my ( $self, $opts ) = @_;
    return $builder_of{ ident $self }->( $self, $opts );
}



# method: BUILD
# Builds an instance of SCat::OfObj
#
#    Takes a single argument which is a hashref (or rather, new takes that argument and passes it on...):
#
#     builder - must be present. A coderef.
#     instancer - optional. One would be generated otherwise.
#    to_guess - optional: an array ref of things that are guessed and passed to the builder in case of a generated instancer.
#    positions - a hash ref, values being keys. This'd be used to specify, for instance, that start is SPos(1)
#    position_finders - a hash ref, values being coderefs. Useful to say that the peak of a mountain can be found by calling this.
#    description_finders - a hashref, values being coderefs.

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    $builder_of{$id} = $opts_ref->{builder} or die "Need builder!";
    
    $positions_of_of{$id}          = $opts_ref->{positions} || {};
    $position_finders_of_of{$id}   = $opts_ref->{position_finders} || {};
    $description_finders_of_of{$id}= $opts_ref->{description_finders} || {};

    $atts_to_be_guessed_of{$id} = $opts_ref->{to_guess} || [];

    my $guesser_ref = $guesser_of_of{$id};

    # install positions into guesser.
    while (my ($k, $v) = each %{$positions_of_of{$id}}) {
        $guesser_ref->{$k} = sub {
            my $object = shift;
            return $object->get_at_position( $v );
        };
    }

    # install position_finders into guesser
    while (my ($k, $v) = each %{$position_finders_of_of{$id}}) {
        $guesser_ref->{$k} = sub {
            my $object = shift;
            return $object->get_subobj_given_range( $v->($object) );
        };
    }

    # install description_finders into guesser
    while (my ($k, $v) = each %{$description_finders_of_of{$id}}) {
        $guesser_ref->{$k} = $v;
    }

    # install instancer unless one provided
    if ($opts_ref->{instancer}) {
        $instancer_of{$id} = $opts_ref->{instancer};
    } else {
        $self->_install_instancer();
    }

}

#
# subsection: Private methods

# method: _install_instancer
# generates the instancer
#
#    This works as follows for base categories. A potential unblemished version is guessed, and the two are checked for being the same.
# 
#     Most derived categories would just use the instancer of their base categories, and do its extra magic at the end, mostly by playing with the returned SBindings object.
#

sub _install_instancer{
    my $self  = shift;
    my $id    = ident $self;

    croak "generate instancer called when instancer already present"
        if $instancer_of{$id};

    my @to_guess = @{ $atts_to_be_guessed_of{$id} };
    my $guesser_ref = $guesser_of_of{$id};
    for (@to_guess) {
        croak "Cannot generate instancer. Do not know how to guess '$_'"
            unless exists $guesser_ref->{$_};
    }

    $instancer_of{$id} = sub {
        my ( $me, $object ) = @_;
        # XXX: Have not taken care of empty objects yet.
        
        my %guess;
        for (@to_guess) {
            my $guess = $guesser_ref->{$_}->($object, $_);
            return unless defined $guess;

            $guess{$_} = $guess;
        }

        my $guess_built = $me->build( \%guess );
        my $slippages   = $object->can_be_seen_as( $guess_built );
        
        if (defined $slippages) {
            return SBindings->create( $slippages, \%guess );
        } else {
            return;
        }

    };

}

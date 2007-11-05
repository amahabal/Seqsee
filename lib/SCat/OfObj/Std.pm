#####################################################
#
#    Package: SCat::OfObj::Std
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

package SCat::OfObj::Std;
use strict;
use Carp;
use Class::Std;
use base qw{SCat::OfObj};
use English qw(-no_match_vars);
use Smart::Comments;


# variable: %name_of
#    Name of the category
my %name_of :ATTR( :get<name> );

# variable: %instancer_of
#    functions called by is_instance
my %instancer_of :ATTR;


# variable: %builder_of
#    buider
my %builder_of :ATTR;

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

# variable: %meto_finder_of_of
#    conatins metonymy finders
my %meto_finder_of_of :ATTR;

# variable: %meto_unfinder_of_of
#    contains blemish appliers
my %meto_unfinder_of_of :ATTR;

# variable: %att_type_of_of
#    The type of attribute (e.g., "int")
my %att_type_of_of :ATTR;

my %sufficient_atts_of_of :ATTR;

my %IS_BLEMISHED_VERSION_OF;
#
# subsection: The public interface

# multi: is_instance ( SCat::OfObj::Std, SObject )
#  for object categories
#  
#    return value:
#      An SBindings object
#
#    possible exceptions:
#        SErr::Think

use Class::Multimethods;
sub Instancer {
    my ( $self, $object ) = @_;
    return $instancer_of{ident $self}->($self, $object);
}

# method: build
# builds an instance of the category
#
#    Takes a single hashref of parameters
sub build{
    my ( $self, $opts ) = @_;
    return $builder_of{ ident $self }->( $self, $opts );
}



# method: BUILD
# Builds an instance of SCat::OfObj::Std
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


    ## Builder called: $opts_ref->{name}, $id 
    
    $builder_of{$id} = $opts_ref->{builder} or confess "Need builder!";
    $name_of{$id}    = $opts_ref->{name};
    confess "Need name" unless defined $name_of{$id};
    
    $positions_of_of{$id}          = $opts_ref->{positions} || {};
    $position_finders_of_of{$id}   = $opts_ref->{position_finders} || {};
    $description_finders_of_of{$id}= $opts_ref->{description_finders} || {};

    $atts_to_be_guessed_of{$id} = $opts_ref->{to_guess} || [];
    $att_type_of_of{$id} = $opts_ref->{att_type} || {};

    $meto_finder_of_of{$id} = $opts_ref->{metonymy_finders} || {};
    $meto_unfinder_of_of{$id} = $opts_ref->{metonymy_unfinders} || {};

    $sufficient_atts_of_of{$id} = $opts_ref->{sufficient_atts} || {};

    my $is_metonyable = (%{$meto_finder_of_of{$id}}) ? 1 : 0;

    my $guesser_ref = $guesser_of_of{$id} = {};
    my $type_ref = $att_type_of_of{$id};
    
    # install positions into guesser.
    while (my ($k, $v) = each %{$positions_of_of{$id}}) {
        ## Guesser installed for: $k
        $guesser_ref->{$k} = sub {
            my $object = shift;
            my $subobject = $object->get_at_position( $v );
            $subobject = $subobject->GetEffectiveObject();
            if (exists $type_ref->{$k} and 
                    $type_ref->{$k} eq 'int') {
                if (ref($subobject) eq "SElement") {
                    return $subobject->get_mag;
                } else {
                    ## $subobject
                    ## $subobject->get_structure
                    my $int = $subobject->can_be_seen_as_int();
                    ## $int
                    return $int;
                } 
            } else {
                return $subobject;
            }
        };
    }

    # install position_finders into guesser
    while (my ($k, $v) = each %{$position_finders_of_of{$id}}) {
        ## Guesser installed for: $k
        $guesser_ref->{$k} = sub {
            my $object = shift;
            ## $object->get_structure
            ## $v->($object)
            my $subobject = $object->get_subobj_given_range( $v->($object) );
            $subobject = $subobject->GetEffectiveObject();
            ## $subobject
            if (exists $type_ref->{$k} and
                    $type_ref->{$k} eq 'int') {
                if (ref($subobject) eq "SElement") {
                    return $subobject->get_mag;
                } else {
                    my $int = $subobject->can_be_seen_as_int();
                    return $int;
                } 
            } else {
                return $subobject;
            }
        };
    }

    # install description_finders into guesser
    while (my ($k, $v) = each %{$description_finders_of_of{$id}}) {
        ## Guesser installed for: $k
        $guesser_ref->{$k} = $v;
    }

    # install instancer unless one provided
    if ($opts_ref->{instancer}) {
        $instancer_of{$id} = $opts_ref->{instancer};
    } else {
        _install_instancer($id);
    }

    $S::IsMetonyable{$self} = $is_metonyable;
    $S::Str2Cat{$self} = $self;
}

#
# subsection: Public Interface

sub get_meto_types{
    my ( $self ) = @_;
    my $id = ident $self;
    return keys %{ $meto_finder_of_of{$id} };
}



# method: get_meto_finder
# Gets meto finder given name
#

sub get_meto_finder{
    my ( $self, $name ) = @_;
    my $id = ident $self;

    return $meto_finder_of_of{$id}{$name};
}



# method: get_meto_unfinder
# Finds the subroutine that undoes metonymy
#

sub get_meto_unfinder{
    my ( $cat, $name ) = @_;
    my $id = ident $cat;

    return $meto_unfinder_of_of{$id}{$name};
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
    my $id  = shift;
    ## install_instancer called for: $id

    croak "generate instancer called when instancer already present"
        if $instancer_of{$id};

    my @to_guess = @{ $atts_to_be_guessed_of{$id} };
    my $guesser_ref = $guesser_of_of{$id};
    ## guesser_ref: $guesser_ref
    for (@to_guess) {
        ## Will check guesser for: $_
        confess "Cannot generate instancer. Do not know how to guess '$_'"
            unless exists $guesser_ref->{$_};
    }

    $instancer_of{$id} = sub {
        my ( $me, $object ) = @_;
        # XXX: Have not taken care of empty objects yet.

        ## Inside Instancer
        
        my %guess;
        for (@to_guess) {
            my $guess = eval { $guesser_ref->{$_}->($object, $_) };
            if (my $o = $EVAL_ERROR) {
                confess $o unless (UNIVERSAL::isa($o, 'SErr::Pos::OutOfRange'));
            }
            return if(not defined $guess);

            $guess{$_} = $guess;
            ## Guessed: $_, $guess
        }

        my $guess_built = $me->build( \%guess );
        ## Structure of built: $guess_built->get_structure()
        ## Object structure: $object->get_structure()
        my $result_of_can_be_seen_as = $object->CanBeSeenAs( $guess_built );
        return unless $result_of_can_be_seen_as;
        ## $result_of_can_be_seen_as,
        my $slippages   = $result_of_can_be_seen_as->GetPartsBlemished() || {};
        ## $slippages

        # Special case: $object is a SElement
        if ($object->isa('SElement')) {
            if (my $entire_blemish = $result_of_can_be_seen_as->GetEntireBlemish()) {
                $slippages = { 0 => $entire_blemish};
            }
        }
        ## $slippages

        return SBindings->create( $slippages, \%guess, $object);
    };

}

#
# subsection: Derivations
# SHould probably be elsewhere...



# method: derive_assuming
# derivative, keeping something fixed
#

sub derive_assuming{
    my ( $category, $assuming_ref ) = @_;

    my $builder = sub {
        my ( $self, $opts_ref ) = @_;
        my %assuming_hash = %$assuming_ref;
        while (my($k, $v) = each %assuming_hash) {
            if (exists $opts_ref->{$k}) {
                confess "This category needs $k=>$v, but got $k=> $opts_ref->{$k} instead" unless $opts_ref->{$k} eq $v;
            } else {
                $opts_ref->{$k} = $v;
            }
        }
        my $ret = $category->build( $opts_ref );

        $ret->add_category($self, SBindings->create( {}, $opts_ref, $ret));
        return $ret;

    };

    my $instancer = sub {
        my ( $me, $object ) = @_;

        my $bindings = $category->is_instance( $object );
        return unless $bindings;

        my $bindings_ref = $bindings->get_bindings_ref;
        ## $bindings_ref
        my %assuming_hash = %$assuming_ref;
        while (my($k, $v) = each %assuming_hash) {
            ## Keys: $k, $v
            return unless ($bindings_ref->{$k} eq $v);
        }
        ## $bindings
        return $bindings;
    };
    my $name = $category->get_name(). " with ". join(", ", %$assuming_ref);

    return SCat::OfObj::Std->new({ builder   => $builder,
                              to_recreate => q{Recreation of derived categories not implemented},
                              name      => $name,
                              instancer => $instancer,
                          });

}



# method: as_text
# returns a short textual description of the category. Name, perhaps?
#
sub as_text :STRINGIFY{
    my ( $self ) = @_;
    return $name_of{ident $self};
}

sub display_self{
    my ( $self, $widget ) = @_;
    $widget->Display("You clicked:", ['heading'], "\n", $self->as_text);
}

sub as_insertlist{
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    my $list = new SInsertList();

    if ($verbosity == 0 or $verbosity == 1) {
        $list->append( $name_of{$id}, "", "\n" );
        return $list;
    }
    die "Verbosity $verbosity not implemented for ". ref $self;
}

sub get_squintability_checker{
    my ( $self ) = @_;
    # XXX(Board-it-up): [2006/12/29] Currently just returns No. Should be different for some categories.
    return;
}

sub derive_blemished{
    my ( $category ) = @_;
    if (exists $IS_BLEMISHED_VERSION_OF{$category}) {
        return $category;
    }
    my $builder = sub {
        my ( $self, $opts_ref ) = @_;
        my $object = $category->build($opts_ref);
        # XXX(Board-it-up): [2006/12/31] Needs work...
        return $object;
    };
    my $instancer = sub {
        my ( $me, $object ) = @_;
        my $bindings = $category->is_instance( $object ) or return;
        return unless $bindings->get_metonymy_mode()->is_metonymy_present();
        return $bindings;
    };
    my $name = 'blemished ' . $category->get_name();
    my $derived_cat = SCat::OfObj::Std->new({builder => $builder,
                                    name => $name,
                                    instancer => $instancer,
                                    to_recreate => 'Recreation Not yet implemented',
                                    });
    $IS_BLEMISHED_VERSION_OF{$derived_cat} = $category;
    return $derived_cat;
}

sub AreAttributesSufficientToBuild{
    my ( $self, @atts ) = @_;
    my $sufficient_atts_ref = $sufficient_atts_of_of{ident $self};
    my $string = join(':', @atts);
    return exists($sufficient_atts_ref->{$string}) ? 1 : 0;
}

1;

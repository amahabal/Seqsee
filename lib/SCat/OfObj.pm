# New base class for categories of objects.

package SCat::OfObj;
use strict;
use Carp;
use Class::Std;
use base qw{SInstance};
use English qw(-no_match_vars);
use Smart::Comments;
use Memoize;
use SUtil;
use List::Util qw(sum shuffle);

my %relation_finder_of :ATTR(:get<relation_finder> :set<relation_finder>);
sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $relation_finder_of{$id} = $opts_ref->{relation_finder} || undef;
}

use Class::Multimethods;
multimethod is_instance => qw(SCat::OfObj SObject) => sub {
    my ( $cat, $object ) = @_;
    my $bindings =  $cat->Instancer( $object ) or return;
    $object->add_category( $cat, $bindings );

    return $bindings;
};

sub is_metonyable{
    my ( $self ) = @_;
    return $S::IsMetonyable{$self};
}

# method: find_metonym
# finds a metonymy
#
#    Arguments:
#    $cat - The category the metonymy will be based on
#    $object - the object whose metonymy is being sought
#    $name - the name of the metonymy, as the cat may support several
#     
#    Please note that the object must already have been seen as belonging to the category.
#     
#    Example:
#    >$cat->find_metonym( $object, $name )

sub find_metonym{
    my ( $cat, $object, $name ) = @_;

    my $finder = $cat->get_meto_finder( $name )
        or croak "No '$name' meto_finder installed for category $cat";
    my $bindings = $object->GetBindingForCategory( $cat ) 
        or croak "Object must belong to category";

    my $obj =  $finder->( $object, $cat, $name, $bindings );
    ## next line kludgy
    if (UNIVERSAL::isa($object, "SAnchored")) {
        $obj->get_starred->set_edges( $object->get_edges );
    }
    
    return $obj;
}

sub get_squintability_checker{
    my ( $self ) = @_;
    # XXX(Board-it-up): [2006/12/29] Currently just returns No. Should be different for some categories.
    return;
}

sub get_meto_types {
    my ( $self ) = @_;
    return;
}
memoize('get_meto_types');
multimethod 'find_relation_type';
sub FindRelationBetween {
    my ( $self, $o1, $o2 ) = @_;
    my $relation_finder = $self->get_relation_finder() || \&Default_FindRelationBetween;
    return $relation_finder->($self, $o1, $o2);
}

sub Default_FindRelationBetween {
    my ( $self, $o1, $o2 ) = @_;
    my $cat = $self;
    my $opts_ref = {};

    $opts_ref->{first}  = $o1;
    $opts_ref->{second} = $o2;

    # Base category
    my $b1 = $o1->is_of_category_p($cat) or return;

    my $b2 = $o2->is_of_category_p($cat) or return;

    $opts_ref->{base_category} = $cat;

    ## Base Category found: $cat

    # Meto mode
    my $meto_mode = $b1->get_metonymy_mode;
    return unless $meto_mode eq $b2->get_metonymy_mode;
    $opts_ref->{base_meto_mode} = $meto_mode;

    ## Base meto mode found: $meto_mode

    CalculateBindingsChange( $opts_ref, $b1->get_bindings_ref(), $b2->get_bindings_ref(), $cat )
        or return;

    ## bindings: %bindings_1, %bindings_2
    ## changed_bindings found: $changed_ref
    ## unchanged_bindings found: $unchanged_ref

    if ( $meto_mode->is_metonymy_present() ) {

        # So other stuff is relevant, too!
        if ( $meto_mode->is_position_relevant() ) {    # Position relevant!
            my $pos_mode = $b1->get_position_mode;
            ## $b2->get_position_mode
            return unless $pos_mode == $b2->get_position_mode;
            $opts_ref->{base_pos_mode} = $pos_mode;
            ## position_mode_found: $pos_mode

            my $rel = find_reln( $b1->get_position(), $b2->get_position() );
            return unless $rel;
            $opts_ref->{position_reln} = $rel;

            my $meto_type_1 = $b1->get_metonymy_type;
            my $meto_type_2 = $b2->get_metonymy_type;
            $rel = find_reln( $meto_type_1, $meto_type_2 );
            return unless $rel;
            $opts_ref->{metonymy_reln} = $rel;

            ## Starred relation, unstarred reln, metonymy_reln?
            ## Need to work that out
        }
    }

    return SReln::Compound->new($opts_ref);
}

sub CalculateBindingsChange {

    # my ( $output_ref, $bindings_1, $bindings_2, $cat ) = @_;
    ##CalculateBindingsChange:

    return 1 if CalculateBindingsChange_no_slips(@_);
    return CalculateBindingsChange_with_slips(@_);
}

sub CalculateBindingsChange_no_slips {
    my ( $output_ref, $bindings_1, $bindings_2, $cat ) = @_;
    ##CalculateBindingsChange_no_slips:
    my $changed_ref   = {};
    my $unchanged_ref = {};
    while ( my ( $k, $v1 ) = each %$bindings_1 ) {
        unless ( exists $bindings_2->{$k} ) {
            confess
              "In _find_reln($$$): binding for $k missing for second object!";
        }
        my $v2 = $bindings_2->{$k};
        if ( $v1 eq $v2 ) {
            $unchanged_ref->{$k} = $v1;
            next;
        }
        my $rel = find_relation_type( $v1, $v2 );
        ## k, v1, v2, rel: $k, $v1, $v2, $rel
        return unless $rel;
        $changed_ref->{$k} = $rel;
    }
    $output_ref->{changed_bindings}   = $changed_ref;
    $output_ref->{unchanged_bindings} = $unchanged_ref;
    return 1;
}

sub CalculateBindingsChange_with_slips {
    my ( $output_ref, $bindings_1, $bindings_2, $cat, $is_reverse ) = @_;

    # An explanation for $is_reverse:
    # For a reln to be valid, it's reverse must be valid too. Thus, a reln 
    # between 1 2 3 and 1 as ascending is not desirable, with no way to get back.
    # So I'll also check for reverse, and is_reverse is true if that is what is
    # happening.

    my $changed_ref   = {};
    my $unchanged_ref = {};
    my $slips_ref     = {};
    ##CalculateBindingsChange_with_slips:

    my @attributes = uniq( keys(%$bindings_2), keys(%$bindings_1) );
  LOOP: while ( my ( $k2, $v2 ) = each %$bindings_2 ) {
        for my $k ( shuffle(@attributes) ) {
            ## k2, k: $k2, $k
            my $v = $bindings_1->{$k};
            ## v2, v: $v2, $v
            if ( $v eq $v2 ) {
                $unchanged_ref->{$k2} = $v2;
                $slips_ref->{$k2}     = $k;
                ## v = v2:
                next LOOP;
            }
            my $rel = find_relation_type( $v, $v2 );
            next unless $rel;
            ## found rel:
            $changed_ref->{$k2} = $rel;
            $slips_ref->{$k2}   = $k;
            next LOOP;
        }
    }
    $output_ref->{changed_bindings}   = $changed_ref;
    $output_ref->{unchanged_bindings} = $unchanged_ref;
    ## checking if atts sufficient: $slips_ref
    return unless $cat->AreAttributesSufficientToBuild( sort keys %$slips_ref );
    ## look sufficient:
    unless ($is_reverse) {
        ## checking reverse:
        return unless CalculateBindingsChange_with_slips({},# don't care
                                                         $bindings_2,
                                                         $bindings_1,
                                                         $cat,
                                                         1 # is_reverse true
                                                             );
        ## reverse ok :
        #print "H";
    }
    $output_ref->{slippages} = $slips_ref;
    return 1;
}

1;

package SStream2;
use strict;
use Carp;
use Smart::Comments;
use Scalar::Util qw(blessed reftype);

my %MEMO;

# Each stream object shall be a blessed hashref (no Class::Std).
sub CreateNew {
    my ( $package, $name, $opts_ref ) = @_;
    confess "Missing name!" unless $name;

    return $MEMO{$name} if $MEMO{$name};
    my $self = bless {}, $package;
    $MEMO{$name} = $self;

    $self->{Name}                  = $name;
    $self->{DiscountFactor}        = $opts_ref->{DiscountFactor} || 0.8;
    $self->{MaxOlderThoughts}      = $opts_ref->{MaxOlderThoughts} || 10;
    $self->{OlderThoughtCount}     = 0;
    $self->{OlderThoughts}         = [];
    $self->{ThoughtsSet}           = {};
    $self->{ComponentStrength}     = {};
    $self->{ComponentOwnership_of} = {};
    $self->{CurrentThought}        = '';
    $self->{vivify}                = {};
    $self->{hit_intensity}         = {};
    $self->{thought_hit_intensity} = {};

    return $self;
}

sub clear {
    my ($self) = @_;
    $self->{OlderThoughtCount}     = 0;
    $self->{OlderThoughts}         = [];
    $self->{ThoughtsSet}           = {};
    $self->{ComponentStrength}     = {};
    $self->{ComponentOwnership_of} = {};
    $self->{CurrentThought}        = '';
    $self->{vivify}                = {};
}

sub add_thought {
    @_ == 2 or confess "new thought takes two arguments";
    my ( $self, $thought ) = @_;

    if ($Global::debugMAX) {
        main::message("Added thought: " . SUtil::StringifyForCarp($thought));
    }
    if ( $Global::Feature{CodeletTree} ) {
        print {$Global::CodeletTreeLogHandle} "Chose $thought\n";
    }

    return if $thought eq $self->{CurrentThought};

    if ( exists $self->{ThoughtsSet}{$thought} ) {    #okay, so this is an older thought
        unshift( @{ $self->{OlderThoughts} }, $self->{CurrentThought} ) if $self->{CurrentThought};
        @{ $self->{OlderThoughts} } = grep { $_ ne $thought } @{ $self->{OlderThoughts} };
        $self->{CurrentThought} = $thought;
        _recalculate_Compstrength();
        $self->{OlderThoughtCount} = scalar( @{ $self->{OlderThoughts} } );
    }

    else {
        $self->antiquate_current_thought() if $self->{CurrentThought};
        $self->{CurrentThought} = $thought;
        $self->{ThoughtsSet}{$thought} = $thought;
        $self->_maybe_expell_thoughts();
    }
    $self->_think_the_current_thought();

}

sub _think_the_current_thought {
    my ($self) = @_;
    my $thought = $self->{CurrentThought};
    return unless $thought;

    my $fringe = $thought->get_fringe();
    ## $fringe
    $thought->set_stored_fringe($fringe);

    my $hit_with = $self->_is_there_a_hit($fringe);
    ## $hit_with

    if ($hit_with) {
        my $new_thought = SCodelet->new(
            'AreRelated',
            100,
            {   a => $hit_with,
                b => $thought
            }
        )->schedule();
    }

    my @codelets;
    for my $x ( $thought->get_actions() ) {
        my $x_type = ref $x;
        if ( $x_type eq "SCodelet" ) {
            push @codelets, $x;
        }
        elsif ( $x_type eq "SAction" ) {

            # print "Action of family ", $x->get_family(), " to be run\n";
            # main::message("Action of family ", $x->get_family());
            if ( $Global::Feature{CodeletTree} ) {
                my $family      = $x->get_family;
                my $probability = $x->get_urgency;
                print {$Global::CodeletTreeLogHandle} "\t$x\t$family\t$probability\n";
            }
            $x->conditionally_run();
        }
        else {
            confess "Huh? non-codelet '$x' returned by get_actions";
        }
    }

    my @choose2
        = scalar(@codelets) > 2
        ? SChoose->choose_a_few_nonzero( 2, [ map { $_->[1] } @codelets ], \@codelets )
        : @codelets;
    SCoderack->add_codelet($_) for @choose2;
}

# method: _maybe_expell_thoughts
# Expells thoughts if $self->{MaxOlderThoughts} exceeded
#

sub _maybe_expell_thoughts {
    my ($self) = @_;
    return unless $self->{OlderThoughtCount} > $self->{MaxOlderThoughts};
    for ( 1 .. $self->{OlderThoughtCount} - $self->{MaxOlderThoughts} ) {
        delete $self->{ThoughtsSet}{ pop @{ $self->{OlderThoughts} } };
    }
    $self->{OlderThoughtCount} = $self->{MaxOlderThoughts};
    $self->_recalculate_Compstrength();
}

#method: _recalculate_Compstrength
# Recalculates the strength of components from scratch
sub _recalculate_Compstrength {
    my ($self)                = @_;
    my $vivify                = $self->{vivify};
    my $ComponentOwnership_of = $self->{ComponentOwnership_of};
    %{$ComponentOwnership_of} = ();
    %{$vivify}                = ();
    for my $t ( @{ $self->{OlderThoughts} } ) {
        my $fringe = $t->get_stored_fringe();
        for my $comp_act (@$fringe) {
            my ( $comp, $act ) = @$comp_act;
            $vivify->{$comp} = $comp;
            $ComponentOwnership_of->{$comp}{$t} = $act;
        }
    }
}

# method: init
# Does nothing.
#
#    Here for symmetry with similarly named methods in Coderack etc

sub init {
}

# method: antiquate_current_thought
# Makes the current thought the first old thought
#

sub antiquate_current_thought {
    my $self = shift;
    unshift( @{ $self->{OlderThoughts} }, $self->{CurrentThought} );
    $self->{CurrentThought} = '';
    $self->{OlderThoughtCount}++;
    $self->_recalculate_Compstrength();
}

# method: _is_there_a_hit
# Is there another thought with a common fringe?
#
# Given the fringe and the extended fringe (each being an array ref, each of
# whose elements are 2 element array refs, the first being a component and the
# second the strength, it checks if there is a hit; If there is, the thought
# with which the hit occured is returned. Perhaps only thoughts of the same
# core type as the current are returned.
sub _is_there_a_hit {
    my ( $self, $fringe_ref ) = @_;
    ## $fringe_ref
    my %components_hit;    # keys values same
    my $hit_intensity = $self->{hit_intensity};
    %$hit_intensity = ();    # keys are components, values numbers

    my $ComponentOwnership_of = $self->{ComponentOwnership_of};

    for my $in_fringe (@$fringe_ref) {
        my ( $comp, $intensity ) = @$in_fringe;
        next unless exists $ComponentOwnership_of->{$comp};
        $components_hit{$comp} = $comp;
        $hit_intensity->{$comp} = $intensity;
    }

    # Now get a list of which thoughts are hit.
    my $thought_hit_intensity = $self->{thought_hit_intensity};
    %$thought_hit_intensity = ();    # keys are thoughts, values intensity

    for my $comp ( values %components_hit ) {
        next unless exists $ComponentOwnership_of->{$comp};
        my $owner_ref = $ComponentOwnership_of->{$comp};
        my $intensity = $hit_intensity->{$comp};
        for my $tht ( keys %$owner_ref ) {
            $thought_hit_intensity->{$tht} += $owner_ref->{$tht} * $intensity;
        }
    }

    return unless %$thought_hit_intensity;

    # Dampen their effect...
    my $dampen_by = 1;
    for my $i ( 0 .. $self->{OlderThoughtCount} - 1 ) {
        $dampen_by *= $self->{DiscountFactor};
        my $thought = $self->{OlderThoughts}[$i];
        next unless exists $thought_hit_intensity->{$thought};
        $thought_hit_intensity->{$thought} *= $dampen_by;
        $thought_hit_intensity->{$thought}
            *= $self->thoughtTypeMatch( $thought, $self->{CurrentThought} );
    }

    my $chosen_thought
        = SChoose->choose( [ values %$thought_hit_intensity ], [ keys %$thought_hit_intensity ] );
    return $self->{ThoughtsSet}{$chosen_thought};
}

{
    my %Mapping = (

    );

    sub thoughtTypeMatch {
        my ( $self, $othertht, $cur_tht ) = @_;
        my ( $type1, $type2 ) = map { blessed($_) } ( $othertht, $cur_tht );

        #main::message("$type1 and $type2");
        return 1 if $type1 eq $type2;
        my $str = "$type1;$type2";
        return $Mapping{$str} if exists $Mapping{$str};

        #main::message("$str barely match!");
        return 0.01;
    }
}

1;

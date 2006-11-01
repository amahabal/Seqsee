#####################################################
#
#    Package: SRelnType::Compound
#
#####################################################
#   Type of relation; Should contain enough info to uniquely identify, and also
#   to resuscicate from string.
#####################################################

package SRelnType::Compound;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use base qw{SRelnType};

my %string_representation_of : ATTR;
my %base_category_of : ATTR;
my %base_meto_mode_of : ATTR;
my %pos_mode_of : ATTR;
my %changed_bindings_of_of : ATTR;
my %position_reln_of : ATTR;
my %metonymy_reln_of : ATTR;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $base_category_of{$id}         = $opts_ref->{base_category};
    $base_meto_mode_of{$id}        = $opts_ref->{base_meto_mode};
    $pos_mode_of{$id}              = $opts_ref->{base_pos_mode};
    $changed_bindings_of_of{$id}   = $opts_ref->{changed_bindings};
    $metonymy_reln_of{$id}         = $opts_ref->{metonymy_reln};
    $position_reln_of{$id}         = $opts_ref->{position_reln};
    $string_representation_of{$id} = $opts_ref->{string};
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $opts_ref ) = @_;
        my %opts = %$opts_ref;

        my $meto_mode = $opts{base_meto_mode};
        if ( not $meto_mode->is_metonymy_present() ) {
            $opts{metonymy_reln} = 'x';    # Don't care.
            $opts{base_pos_mode} = 'x';
        }
        if ( not $meto_mode->is_position_relevant() ) {
            $opts{position_reln} = ' x';
        }

        my %changed_bindings = %{ $opts_ref->{changed_bindings} };

        my $string = join(
            '#',
            @opts{
                qw(base_category base_meto_mode metonymy_reln base_pos_mode
                    position_reln                                       )
                },
            join( ";", map { "$_=>" . $changed_bindings{$_}->get_type() } keys %changed_bindings )
        );

        ## attempted creation: $string
        return $MEMO{$string} ||= $package->new( \%opts );
    }

    sub get_dependent_memories {
        my ($self) = @_;
        my $id = ident $self;

        return grep { ref($_) }    # To weed out the 'x's
            (
            $base_category_of{$id}, $base_meto_mode_of{$id}, $pos_mode_of{$id},
            $position_reln_of{$id}, $metonymy_reln_of{$id}, values %{ $changed_bindings_of_of{$id} }
            );
    }

    sub as_dump {
        my ($self) = @_;
        my $id = ident $self;
        my @set = grep { ref($_) ? GetLTMIndex($_) : $_ }    # To weed out the 'x's
            (
            $base_category_of{$id}, $base_meto_mode_of{$id},
            $pos_mode_of{$id},      $position_reln_of{$id},
            $metonymy_reln_of{$id}, %{ $changed_bindings_of_of{$id} }
            );
        return join( ';', @set );
    }

    sub resuscicate {
        my ( $package, $string ) = @_;

        # Assumption: all components already resuscicated.
        my ( $cat_id, $meto_mode_of, $pos_mode_of, $posn_reln, $meto_reln, %change )
            = map { $_ =~ /^\d+$/o ? GetAtLTMIndex($_) : $_ } split( ';', $string );

        return $package->create(
            {   base_category    => $cat_id,
                base_meto_mode   => $meto_mode_of,
                base_pos_mode    => $pos_mode_of,
                metonymy_reln    => $meto_reln,
                position_reln    => $posn_reln,
                changed_bindings => \%change,
            }
        );
    }
}

sub as_text {
    my ($self) = @_;
    return $string_representation_of{ ident $self};
}

1;

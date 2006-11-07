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

use Class::Multimethods;
for (qw{apply_reln_direction}) {
    multimethod $_;
}

my %string_representation_of : ATTR;
my %base_category_of : ATTR(:get<base_category>);
my %base_meto_mode_of : ATTR(:get<base_meto_mode>);
my %pos_mode_of : ATTR(:get<base_pos_mode>);
my %changed_bindings_of_of : ATTR(:get<changed_bindings_ref>);
my %position_reln_of : ATTR(:get<position_reln>);
my %metonymy_reln_of : ATTR(:get<metonymy_reln>);
my %direction_reln_of : ATTR(:get<direction_reln>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $base_category_of{$id}         = $opts_ref->{base_category};
    $base_meto_mode_of{$id}        = $opts_ref->{base_meto_mode};
    $pos_mode_of{$id}              = $opts_ref->{base_pos_mode};
    $changed_bindings_of_of{$id}   = $opts_ref->{changed_bindings};
    $metonymy_reln_of{$id}         = $opts_ref->{metonymy_reln};
    $position_reln_of{$id}         = $opts_ref->{position_reln};
    $string_representation_of{$id} = $opts_ref->{string};
    $direction_reln_of{$id}        = $opts_ref->{dir_reln};
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $opts_ref ) = @_;
        my %opts = %$opts_ref;

        confess "Need dir_reln" unless defined $opts{dir_reln};

        my $meto_mode = $opts{base_meto_mode};
        if ( not $meto_mode->is_metonymy_present() ) {
            $opts{metonymy_reln} = 'x';    # Don't care.
            $opts{base_pos_mode} = 'x';
        }
        if ( not $meto_mode->is_position_relevant() ) {
            $opts{position_reln} = ' x';
        }

        my %changed_bindings = %{ $opts_ref->{changed_bindings} };

        # XXX(Board-it-up): [2006/11/01] should include dir_reln.

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
}

sub as_text {
    my ($self) = @_;
    return $string_representation_of{ ident $self};
}

multimethod apply_reln => qw(SRelnType::Compound SObject) => sub {
    my ( $reln, $object ) = @_;

    # Find category for new object
    my $cat = $reln->get_base_category;

    # Make sure the object belongs to that category
    my $bindings = $object->describe_as($cat);
    $bindings->TellDirectedStory( $object, $reln->get_base_pos_mode() );
    ## $bindings
    ## $cat->as_text
    return unless $bindings;

    # Find the bindings for it.
    my $bindings_ref         = $bindings->get_bindings_ref;
    my $changed_bindings_ref = $reln->get_changed_bindings_ref;
    my $new_bindings_ref     = {};

    while ( my ( $k, $v ) = each %$bindings_ref ) {
        ## $k, $v: $k, $v
        if ( exists $changed_bindings_ref->{$k} ) {
            ## cbr: $changed_bindings_ref->{$k}
            $new_bindings_ref->{$k} = apply_reln( $changed_bindings_ref->{$k}, $v );
            next;
        }
        ## handled
        # no change...
        $new_bindings_ref->{$k} = $v;
    }
    my $ret_obj = $cat->build($new_bindings_ref);
    ## $new_bindings_ref
    # We have not "applied the blemishes" yet, of course

    my $reln_meto_mode   = $reln->get_base_meto_mode;
    my $object_meto_mode = $bindings->get_metonymy_mode;
    unless ( $reln_meto_mode == $object_meto_mode ) {
        ## reln_meto_mode isnot object_meto_mode
        return;
    }

    unless ( $reln_meto_mode == METO_MODE::NONE() ) {

        # Calculate the metonymy type of the new object
        my $new_metonymy_type
            = apply_reln( $reln->get_metonymy_reln, $bindings->get_metonymy_type );
        return unless $new_metonymy_type;

        if ( $reln_meto_mode == 3 ) {
            $ret_obj = $ret_obj->apply_blemish_everywhere($new_metonymy_type);
        }
        else {

            # If we get here, position is relevant!
            my $new_position = apply_reln( $reln->get_position_reln, $bindings->get_position );
            ## new_blemish position: $new_position->get_name()
            return unless $new_position;
            ## $reln->get_position_reln()->get_text()
            ## $bindings->get_position()->get_index
            ## $new_position->get_index()
            ## $reln_meto_mode

            ## $bindings->get_metonymy_type()->get_info_loss()
            ## $reln->get_metonymy_reln()->get_change_ref()
            ## $new_metonymy_type->get_info_loss()

            ## $new_object->get_structure
            $ret_obj = $ret_obj->apply_blemish_at( $new_metonymy_type, $new_position );
            ## new object: $ret_obj->get_structure
        }
    }

    $ret_obj->describe_as($cat);

    my $rel_dir = $reln->get_direction_reln;
    my $obj_dir = $object->get_direction;
    my $new_dir = apply_reln_direction( $rel_dir, $obj_dir );

    $ret_obj->set_direction($new_dir);
    return $ret_obj;

};

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;

    return grep { ref($_) } (
        $base_category_of{$id}, $base_meto_mode_of{$id},
        $pos_mode_of{$id},      $position_reln_of{$id},
        $metonymy_reln_of{$id}, $direction_reln_of{$id},
        values %{ $changed_bindings_of_of{$id} }
    );
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;

    return SLTM::encode(
        $base_category_of{$id}, $base_meto_mode_of{$id}, $pos_mode_of{$id},
        $position_reln_of{$id}, $metonymy_reln_of{$id},  $direction_reln_of{$id},
        $changed_bindings_of_of{$id}
    );
}

sub deserialize {
    my ( $package, $str ) = @_;
    my %opts;
    @opts{
        qw(base_category base_meto_mode base_pos_mode position_reln
            metonymy_reln dir_reln changed_bindings)
        }
        = SLTM::decode($str);
    return $package->create( \%opts );
}

sub get_type { $_[0] }

1;

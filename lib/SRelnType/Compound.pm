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
use Memoize;

use Class::Multimethods;
for (qw{apply_reln}) {
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
my %slippages_of : ATTR(:get<slippages_ref>);    #key: new attribute, val: old att

my %complexity_penalty_of :ATTR(:get<complexity_penalty>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $base_category_of{$id}         = $opts_ref->{base_category};
    $base_meto_mode_of{$id}        = $opts_ref->{base_meto_mode};
    $pos_mode_of{$id}              = $opts_ref->{base_pos_mode};
    $changed_bindings_of_of{$id}   = $opts_ref->{changed_bindings};
    $slippages_of{$id}             = $opts_ref->{slippages} || {};
    $metonymy_reln_of{$id}         = $opts_ref->{metonymy_reln};
    $position_reln_of{$id}         = $opts_ref->{position_reln};
    $string_representation_of{$id} = $opts_ref->{string};
    $direction_reln_of{$id}        = $opts_ref->{dir_reln};

    $complexity_penalty_of{$id} = $self->CalculateComplexityPenalty();
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
            join( ";", map { "$_=>" . $changed_bindings{$_}->get_type() } keys %changed_bindings ),
            join( ';', %{ $opts{slippages} || {} } ),
        );

        ## attempted creation: $string
        $opts{string} = $string;
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
    my $id = ident $self;

    my $basecat          = $base_category_of{$id}->as_text();
    my $changed_bindings = $changed_bindings_of_of{$id};
    my $changed_bindings_string;
    my $metonymy_presence = $base_meto_mode_of{$id}->is_metonymy_present() ? '*' : '';
    my %slippages = %{ $slippages_of{$id} };
    if (%slippages) {
        while ( my ( $new, $old ) = each %slippages ) {
            my $reln_for_this_attribute = $changed_bindings->{$new};
            if ($reln_for_this_attribute) {
                $changed_bindings_string .= "$new => " . $reln_for_this_attribute->as_text();
                $changed_bindings_string .= " (of $old)" if $old ne $new;
                $changed_bindings_string .= ';';
            }
            else {
                if ( $old ne $new ) {
                    $changed_bindings_string .= "new $new is the earlier $old;";
                }
            }
        }
    }
    else {
        while ( my ( $k, $v ) = each %$changed_bindings ) {
            $changed_bindings_string .= "$k => " . $v->as_text() . ";";
        }
    }
    chop($changed_bindings_string);

    return "[$basecat$metonymy_presence]  $changed_bindings_string";
}

multimethod apply_reln => qw(SRelnType::Compound SObject) => sub {
    my ( $reln, $original_object ) = @_;
    my $object = $original_object->GetEffectiveObject();

    # Find category for new object
    my $cat = $reln->get_base_category;

    # Make sure the object belongs to that category
    my $bindings = $object->describe_as($cat) or return;
    $bindings->TellDirectedStory( $object, $reln->get_base_pos_mode() );
    ## $bindings
    ## $cat->as_text

    # Find the bindings for it.
    my $bindings_ref         = $bindings->get_bindings_ref;
    my $changed_bindings_ref = $reln->get_changed_bindings_ref;
    my $slippages_ref        = $reln->get_slippages_ref();
    my $new_bindings_ref     = {};

    if (%$slippages_ref) {
        for my $att ( keys %$slippages_ref ) {
            my $old_attr = $slippages_ref->{$att} or next;
            my $val = $bindings_ref->{$old_attr};
            if ( exists $changed_bindings_ref->{$att} ) {
                $new_bindings_ref->{$att} = apply_reln( $changed_bindings_ref->{$att}, $val );
                next;
            }
            $new_bindings_ref->{$att} = $val;
        }
    }
    else {

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

        if ( $reln_meto_mode == METO_MODE::ALL() ) {
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
            my $blemished;
            eval { $blemished = $ret_obj->apply_blemish_at( $new_metonymy_type, $new_position ); };
            ## new object: $ret_obj->get_structure
            return unless $blemished;
            $ret_obj = $blemished;
        }
    }

    $ret_obj->describe_as($cat);
    $ret_obj->TellDirectedStory( $cat, $reln->get_base_pos_mode() );
    my $rel_dir = $reln->get_direction_reln;
    my $obj_dir = $object->get_direction;
    my $new_dir = apply_reln( $rel_dir, $obj_dir );

    $ret_obj->set_direction($new_dir);
    $ret_obj->set_group_p(1);
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

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    if ( $verbosity == 0 ) {
        return new SInsertList( "SRelnType::Compound", "heading", "\n" );
    }

    if ( $verbosity == 1 ) {
        my $list = new SInsertList;
        $list->append( "Base Category: ", "heading2", "\n" );
        $list->concat( $base_category_of{$id}->as_insertlist(1)->indent(1) );

        $list->append( "Base Meto mode: ", "heading2", "\n" );
        $list->concat( $base_meto_mode_of{$id}->as_insertlist(0)->indent(1) );
        $list->append("\n");

        if ( ref $pos_mode_of{$id} ) {
            $list->append( "Base Pos Mode: ", "heading2", "\n" );
            $list->concat( $pos_mode_of{$id}->as_insertlist(0)->indent(1) );
            $list->append("\n");
        }

        $list->append( "Changed Bindings: ", "heading2", "\n" );
        while ( my ( $k, $v ) = each %{ $changed_bindings_of_of{$id} } ) {
            my $sublist = new SInsertList;
            $sublist->append( $k, "", "\t", "" );
            $sublist->concat( $v->as_insertlist(0)->indent(1) );
            $sublist->append("\n");
            $list->concat( $sublist->indent(1) );
        }
        return $list;
    }

    confess "Verbosity $verbosity not implemented for " . ref $self;
}

sub suggest_cat_for_ends {
    my ($self)              = @_;
    my $id                  = ident $self;
    my $base_meto_mode      = $base_meto_mode_of{$id};
    my $is_metonymy_present = $base_meto_mode->is_metonymy_present();

    my $base_category = $base_category_of{$id};

# XXX(Board-it-up): [2006/12/31] I should also take into account unchanged bindings as a basis for more specific categories...
    return unless $is_metonymy_present;
    return $base_category->derive_blemished();
}

sub suggest_cat {
    my $self = shift;
    return SCat::OfObj::RelationTypeBased->Create($self);
}
memoize('suggest_cat');

sub CalculateComplexityPenalty {
    my ( $self ) = @_;
    my $id = ident $self;

    my $return = 1;

    # Slippages penalty
    while (my($k, $v) = each %{$slippages_of{$id}}) {
        $return *= 0.8 if $k ne $v; 
    }

    # Changed bindings penalty
    while (my($k, $v) = each %{$changed_bindings_of_of{$id}}) {
        $return *= $v->get_complexity_penalty;
    }

    # Complex metonymy change penalty
    my $base_meto_mode = $base_meto_mode_of{$id};
    if ($base_meto_mode->is_metonymy_present()) {
        $return *= $position_reln_of{$id}->CalculateComplexityPenalty() if $base_meto_mode->is_position_relevant();
        $return *= $metonymy_reln_of{$id}->CalculateComplexityPenalty();
    }

    return $return;
}

sub IsEffectivelyASamenessRelation {
    my ( $self ) = @_;
    my $id = ident $self;
    while (my($k, $v) = each %{$slippages_of{$id}}) {
        return if $k ne $v; 
    }
    return if %{$changed_bindings_of_of{$id}};
    my $base_meto_mode = $base_meto_mode_of{$id};
    if ($base_meto_mode->is_metonymy_present()) {
        return unless $position_reln_of{$id}->IsEffectivelyASamenessRelation();
        return unless $metonymy_reln_of{$id}->IsEffectivelyASamenessRelation();
    }
    return 1;
}
memoize('IsEffectivelyASamenessRelation');

1;

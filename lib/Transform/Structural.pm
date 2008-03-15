package Transform::Structural;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use Memoize;
use base qw{Transform};

my %category_of : ATTR(:name<category>);
my %meto_mode_of : ATTR(:name<meto_mode>);

# ASSUMPTION: pos_mode_of is always forward.

my %position_reln_of : ATTR(:name<position_reln>);
my %metonymy_reln_of : ATTR(:name<metonymy_reln>);
my %direction_reln_of : ATTR(:name<direction_reln>);

my %slippages_of : ATTR(:name<slippages>); # Key: new attribute, Val: old attribute.
my %changed_bindings_of_of : ATTR(:name<changed_bindings>); # Key: new attribute. Val: the transform.

sub create {
    my ( $package, $opts_ref ) = @_;
    my $meto_mode = $opts_ref->{meto_mode} or confess "need meto_mode";
    if ( not $meto_mode->is_metonymy_present() ) {
        $opts_ref->{metonymy_reln} = 'x';
    }
    if ( not $meto_mode->is_position_relevant() ) {
        $opts_ref->{position_reln} = 'x';
    }

    my $string = join( '#',
        ( map { $opts_ref->{$_} } qw(category meto_mode metonymy_reln position_reln direction_reln) ),
        join( ';', SUtil::hash_sorted_as_array( %{ $opts_ref->{changed_bindings} } ) ),
        join( ';', SUtil::hash_sorted_as_array( %{ $opts_ref->{slippages} } ) ),
    );
    state %MEMO;
    return $MEMO{$string} ||= $package->new($opts_ref);
}

sub FlippedVersion {
    my ($self) = @_;
    my $id = ident $self;

    ## Flipping: $self->as_text()

    my $new_slippages       = _FlipSlippages( $slippages_of{$id} )  // return;
    my $new_bindings_change = _FlipChangedBindings( $changed_bindings_of_of{$id},
                                                    $slippages_of{$id}
                                                        ) // return;

    ## new_slippages: $new_slippages
    ## new_bindings_change: $new_bindings_change

    my $new_position_reln   = $position_reln_of{$id}->FlippedVersion()
        if ref( $position_reln_of{$id} );
    my $new_metonymy_reln = $metonymy_reln_of{$id}->FlippedVersion()
        if ref( $metonymy_reln_of{$id} );
    my $new_direction_reln = $direction_reln_of{$id}->FlippedVersion()
        if ref( $direction_reln_of{$id} );

    my $flipped = Transform::Structural->create(
        {   category         => $category_of{$id},
            meto_mode        => $meto_mode_of{$id},
            position_reln    => $new_position_reln,
            metonymy_reln    => $new_metonymy_reln,
            direction_reln   => $new_direction_reln,
            changed_bindings => $new_bindings_change,
            slippages        => $new_slippages,
        }
    );
    $flipped->CheckSanity() or main::message( "Flip problematic!" . join(';', %$new_bindings_change));
    return $flipped;
}

memoize('FlippedVersion');

sub _FlipChangedBindings {
    my ($old_bindings, $slippages) = @_;
    my %new_bindings;
    my %old_bindings = %$old_bindings;
    while ( my ( $k, $v ) = each %old_bindings ) {
        my $new_v = $v->FlippedVersion() // return;
        my $new_k;
        if (exists $slippages->{$k}) {
            $new_k = $slippages->{$k};
        } else {
            $new_k = $k;
        }
        $new_bindings{$new_k} = $new_v;
    }
    return \%new_bindings;
}

sub _FlipSlippages {
    my ($old_slippages) = @_;
    my %new_slippages;
    my %keys_seen;
    my %old_slippages = %$old_slippages; 
    while ( my ( $k, $v ) = each %old_slippages ) {
        return if $keys_seen{$v}++;
        $new_slippages{$v} = $k;
    }
    return \%new_slippages;
}

sub get_pure {
    return $_[0];
}

sub IsEffectivelyASamenessRelation {
    my ($self) = @_;
    my $id = ident $self;
    while ( my ( $k, $v ) = each %{ $slippages_of{$id} } ) {
        return unless $k eq $v;
    }
    while ( my ( $k, $v ) = each %{ $changed_bindings_of_of{$id} } ) {
        return unless $v->IsEffectivelyASamenessRelation();
    }
    if ( $meto_mode_of{$id}->is_metonymy_present() ) {
        return unless $metonymy_reln_of{$id}->IsEffectivelyASamenessRelation();
        return unless $direction_reln_of{$id}->IsEffectivelyASamenessRelation();
        if ( $meto_mode_of{$id}->is_position_relevant() ) {
            return unless $position_reln_of{$id}->IsEffectivelyASamenessRelation();
        }
    }

    return 1;
}

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
    my $base_meto_mode = $meto_mode_of{$id};
    if ($base_meto_mode->is_metonymy_present()) {
        $return *= $position_reln_of{$id}->CalculateComplexityPenalty() if $base_meto_mode->is_position_relevant();
        $return *= $metonymy_reln_of{$id}->CalculateComplexityPenalty();
    }

    return $return;
}

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;

    return grep { ref($_) } (
        $category_of{$id}, $meto_mode_of{$id},
        $position_reln_of{$id},
        $metonymy_reln_of{$id}, $direction_reln_of{$id},
        values %{ $changed_bindings_of_of{$id} }
    );
}

sub get_complexity_penalty {
    my ( $self ) = @_;
    return $self->CalculateComplexityPenalty();
}
memoize('get_complexity_penalty');

sub as_text {
    my ( $self ) = @_;
    my $id = ident $self;
    my $cat_name = $category_of{$id}->get_name();
    my $changed_bindings = $changed_bindings_of_of{$id};
    my $changed_bindings_string;
    my $metonymy_presence = $meto_mode_of{$id}->is_metonymy_present() ? '*' : '';
    my %slippages = %{ $slippages_of{$id} };
    if (%slippages) {
        while ( my ( $new, $old ) = each %slippages ) {
            my $reln_for_this_attribute = $changed_bindings->{$new};
            if ($reln_for_this_attribute) {
                $changed_bindings_string .= "($new => " . $reln_for_this_attribute->as_text();
                $changed_bindings_string .= " (of $old)";
                $changed_bindings_string .= ');';
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
    return "[$cat_name$metonymy_presence] $changed_bindings_string";
}

sub serialize {
    my ( $self ) = @_;
    my $id = ident $self;
    return SLTM::encode($category_of{$id}, $meto_mode_of{$id}, $metonymy_reln_of{$id}, $direction_reln_of{$id},
                        $position_reln_of{$id}, $changed_bindings_of_of{$id}, $slippages_of{$id}
                            );
}

sub deserialize {
    my ( $package, $string ) = @_;
    my %opts;
    @opts{qw{category meto_mode metonymy_reln direction_reln position_reln changed_bindings slippages}} = SLTM::decode($string);
    $package->create(\%opts);
}

sub get_complexity {
    my ($self) = @_;
    my $id = ident $self;

    my $complexity_of_category;
    given ( $category_of{$id} ) {
        when ( [ $S::ASCENDING, $S::DESCENDING, $S::SAMENESS ] ) { $complexity_of_category = 0.1 }
        when ( $_->isa('SCat::OfObj::Interlaced') ) {
            $complexity_of_category = 0.1 * $_->get_parts_count();
        }
        default { $complexity_of_category = 0.3;}
    }

    my $total_complexity = $complexity_of_category;
    given ($meto_mode_of{$id}) {
        when ($METO_MODE::NONE) {}
        default { $total_complexity += 0.2; }
    }

    for (values %{$changed_bindings_of_of{$id}}) {
        $total_complexity += $_->get_complexity();
    }

    my %slippages = %{$slippages_of{$id}};
    while (my($k, $v) = each %slippages) {
        $total_complexity += 0.2 unless $k eq $v;
    }

    $total_complexity = 0.9 if $total_complexity > 0.9;
    return $total_complexity;
}

1;
